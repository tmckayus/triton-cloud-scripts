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
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHERG
# DEALINGS IN THE SOFTWARE.

variable "prefix_name" {
  description = "Prefix to append with random string for generating resource names (including instance name)"
  type        = string
  default     = "triton"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "g4dn.xlarge"
}

variable "instance_region" {
  description = "The EC2 region in which to create the instance."
  type        = string
  default     = "us-east-1"
}

variable "model_repository_region" {
  description = "The EC2 region of the model repository bucket. Defaults to instance region if unset."
  type        = string
  default     = ""
}

variable "ssh_cidr_blocks" {
  description = "The cidr blocks to use for the incoming ssh port (22)"
  type        = list
  default     = ["0.0.0.0/0"]
}

variable "server_cidr_blocks" {
  description = "The cidr blocks to use for the incoming ports (30000,30001)"
  type        = list
  default     = ["0.0.0.0/0"]
}

variable "outgoing_cidr_blocks" {
  description = "The cidr blocks to use for outgoing traffic on all ports"
  type        = list
  default     = ["0.0.0.0/0"]
}

variable "additional_security_groups" {
  description = "The names of additional security groups created outside of Terraform to add to the instance."
  type        = list
  default     = []
}

variable "instance_ami_name" {
  description = "The pattern(s) used to filter available AMIs by name to select an image for the instance. May include wildcards."
  type        = list
  default     = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
}

variable "instance_ami_arch" {
  description = "The pattern(s) used to filter available AMIs by architecture to select an image for the instance. May include wildcards."
  type        = list
  default     = ["x86_64"]
}

variable "instance_ami_owner" {
  description = "The pattern(s) used to filter available AMIs by owner to select an image for the instance. May include wildcards."
  type        = list
  default     = ["amazon"]
}

# AWS determines the default user account based on the AMI used.
# Here is a guide to determine the default user
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managing-users.html
variable "user" {
  description = "The default user account for the instance. Based on the AMI type, see AWS documentation"
  type        = string
  default     = "ubuntu"
}

variable "instance_root_volume_size" {
  description = "The size of the root volume in gigabytes."
  type        = number
  default     = 128 # in GB
}

variable "public_key_path" {
  description = "The path of the public key file to use for ssh."
  type        = string
}

variable "private_key_path" {
  description = "The path of the private key file to use for ssh."
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS secret access key used to read model repository from an s3 bucket"
  type = string
}

variable "aws_access_key_id" {
  description = "AWS access key id used to read model repository from an s3 bucket"
  type = string
}

variable "aws_session_token" {
  description = "AWS session token used to read model repository from an s3 bucket"
  type = string
  default = ""
}

variable "model_repository" {
  description = "Model repository path"
  type = string
}
