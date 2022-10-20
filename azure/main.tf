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
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~>4.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.1.1"
    }
  } 
}

provider "azurerm" {
  features {}
}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = lower(random_pet.rg_name.id)
}

# Create virtual network
resource "azurerm_virtual_network" "cuopt_network" {
  name                = "cuopt_vnet"
  address_space       = var.network_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "cuopt_subnet" {
  name                 = "cuopt_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.cuopt_network.name
  address_prefixes     = var.subnet_address_prefixes
}

# Create public IPs
resource "azurerm_public_ip" "cuopt_public_ip" {
  name                = "cuopt_public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "cuopt_sg" {
  name                = "cuopt_sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  direction                   = "Inbound"
  priority                    = "300"
  access                      = var.ssh_port_access
  protocol                    = "Tcp"
  source_port_range           = var.ssh_source_port_range
  destination_port_range      = "22"
  source_address_prefixes     = var.ssh_source_address_prefixes
  destination_address_prefix  = var.ssh_destination_address_prefix
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.cuopt_sg.name
}

resource "azurerm_network_security_rule" "port30000" {
  name                       = "cuopt_api"
  direction                  = "Inbound"
  priority                   = "301"
  access                     = var.triton_port_access
  protocol                   = "Tcp"
  source_port_range          = var.triton_source_port_range
  destination_port_range     = "30000-30001"
  source_address_prefixes    = var.triton_source_address_prefixes
  destination_address_prefix  = var.triton_destination_address_prefix
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.cuopt_sg.name  
}

# Create network interface
resource "azurerm_network_interface" "cuopt_nic" {
  depends_on = [
    azurerm_network_security_rule.port30000,
    azurerm_network_security_rule.ssh
  ]
  name                = "cuopt_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "cuopt_nic_config"
    subnet_id                     = azurerm_subnet.cuopt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cuopt_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "cuopt_security" {
  network_interface_id      = azurerm_network_interface.cuopt_nic.id
  network_security_group_id = azurerm_network_security_group.cuopt_sg.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "cuopt_server" {
  name                  = var.instance_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.cuopt_nic.id]
  size                  = var.instance_size
  os_disk {
    name                 = "cuopt_os_disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.instance_root_volume_size
  }

  source_image_reference {
    publisher = var.instance_image_publisher
    offer     = var.instance_image_offer
    sku       = var.instance_image_sku
    version   = var.instance_image_version
  }

  computer_name                   = "cuopt"
  admin_username                  = var.user
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.user
    public_key = "${file(var.public_key_path)}"
  }

}

output "outputs" {
  value = {
            "resource_group": azurerm_resource_group.rg.name,
            "machine": azurerm_linux_virtual_machine.cuopt_server.name,
            "ip": azurerm_linux_virtual_machine.cuopt_server.public_ip_address,
            "user": var.user,
            "private_key_path": var.private_key_path,
          }
}

resource "null_resource" "install-cnc" {
  depends_on = [
    azurerm_linux_virtual_machine.cuopt_server
  ]
  connection {
    type        = "ssh"
    user        = var.user
    private_key = "${file(var.private_key_path)}"
    host        = "${azurerm_linux_virtual_machine.cuopt_server.public_ip_address}"
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
resource "null_resource" "start-cuopt" {
  depends_on = [
    null_resource.install-cnc
  ]
  connection {
    type        = "ssh"
    user        = var.user
    private_key = "${file(var.private_key_path)}"
    host        = "${azurerm_linux_virtual_machine.cuopt_server.public_ip_address}"
  }

  provisioner "remote-exec" {
    inline = [<<EOT
      AZURE_STORAGE_ACCOUNT=${var.azure_storage_account} AZURE_STORAGE_KEY=${var.azure_storage_key} MODEL_REPOSITORY=${var.model_repository} scripts/triton-helm.sh 2>&1 | tee logs/triton-helm.log
    EOT
    ]
  }
}

resource "null_resource" "wait-cuopt" {
  depends_on = [
    null_resource.start-cuopt
  ]
  connection {
    type        = "ssh"
    user        = var.user
    private_key =  "${file(var.private_key_path)}"    
    host        = "${azurerm_linux_virtual_machine.cuopt_server.public_ip_address}"
  }

  provisioner "remote-exec" {
    inline = [<<EOT
      scripts/wait-triton.sh 2>&1 | tee logs/wait-triton.log
    EOT
    ]
  }
}
