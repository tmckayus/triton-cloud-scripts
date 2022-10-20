# SPDX-FileCopyrightText: Copyright (c) 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: MIT

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30"
    }   
    template = {
      source = "hashicorp/template"
      version = "~> 2.2.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.4.3"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.1.1"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.instance_region
}

resource "random_pet" "pet" {
  prefix = var.prefix_name
}

resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "triton-server" {
  name = lower(random_pet.pet.id)
  vpc_id = "${aws_default_vpc.default.id}"

  #Incoming traffic
  ingress {
    from_port = 30000
    to_port = 30000
    protocol = "tcp"
    cidr_blocks = var.server_cidr_blocks
  }

  ingress {
    from_port = 30001
    to_port = 30001
    protocol = "tcp"
    cidr_blocks = var.server_cidr_blocks
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  #Outgoing traffic
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = var.outgoing_cidr_blocks
  }
}

data "aws_security_groups" "additional-security-groups" {
  filter {
     name = "group-name"
     values = var.additional_security_groups
  }
}

data "aws_ami" "osimage" {
  most_recent = true

  filter {
    name   = "name"
    values = var.instance_ami_name
  }

  filter {
    name = "architecture"
    values = var.instance_ami_arch
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = var.instance_ami_owner
}

resource "aws_key_pair" "triton" {
  key_name   = lower(random_pet.pet.id)
  public_key = file(var.public_key_path)
}

resource "aws_instance" "triton_server" {
  ami           = data.aws_ami.osimage.id
  instance_type = var.instance_type
  key_name = aws_key_pair.triton.key_name
  
  vpc_security_group_ids = concat([aws_security_group.triton-server.id], data.aws_security_groups.additional-security-groups.ids)
  root_block_device {
    volume_size = var.instance_root_volume_size 
  } 
  tags = {
    Name = lower(random_pet.pet.id)
  }
}

output "outputs" {
  value = {
            "machine": aws_instance.triton_server.tags.Name,
            "ip": aws_instance.triton_server.public_ip,
            "user": var.user,
            "private_key_path": var.private_key_path
          }
}

resource "null_resource" "install-cnc" {
  depends_on = [
    aws_instance.triton_server
  ]
  connection {
    type        = "ssh"
    user        = var.user
    private_key = "${file(var.private_key_path)}"
    host        = "${aws_instance.triton_server.public_ip}"
  }

  provisioner "file" {
    source      = "${path.module}/../scripts"
    destination = "scripts"
  }

  provisioner "file" {
    source      = "${path.module}/../tritoninferenceserver"
    destination = "tritoninferenceserver"
  }

  provisioner "file" {
    source      = "${path.module}/overrides"
    destination = "overrides"
  }

  provisioner "remote-exec" {
    inline = [<<EOT
      chmod +x scripts/*.sh;
      mkdir logs;
      cp -r overrides/scripts/* scripts/;
      cp -r overrides/tritoninferenceserver/* tritoninferenceserver/;
      scripts/install-cnc.sh 2>&1 | tee logs/install-cnc.log;
      scripts/wait-cnc.sh   2>&1 | tee logs/wait-cnc.log;
    EOT
    ]
  }
}

# Break this out separately because the presence of var.api_key
# causes logging to be suppressed by Terraform
resource "null_resource" "start-triton" {
  depends_on = [
    null_resource.install-cnc
  ]
  connection {
    type        = "ssh"
    user        = var.user
    private_key = "${file(var.private_key_path)}"
    host        = "${aws_instance.triton_server.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [<<EOT
      AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key} AWS_ACCESS_KEY_ID=${var.aws_access_key_id} AWS_SESSION_TOKEN=${var.aws_session_token} MODEL_REPOSITORY=${var.model_repository} MODEL_REPOSITORY_REGION=${var.model_repository_region != "" ? var.model_repository_region : var.instance_region} scripts/triton-helm.sh 2>&1 | tee logs/triton-helm.log
    EOT
    ]
  }
}

resource "null_resource" "wait-triton" {
  depends_on = [
    null_resource.start-triton
  ]
  connection {
    type        = "ssh"
    user        = var.user
    private_key = "${file(var.private_key_path)}"
    host        = "${aws_instance.triton_server.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [<<EOT
      scripts/wait-triton.sh 2>&1 | tee logs/wait-triton.log
    EOT
    ]
  }
}
