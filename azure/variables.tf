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

variable "instance_name" {
  description = "Name of the linux virtual machine instance"
  type        = string
  default     = "triton"
}

# Publisher, offer, sku, and version are used together to identify the OS image
variable "instance_image_publisher" {
  description = "The 'publisher' attribute of the OS image"
  type        = string
  default     = "Canonical"
}

variable "instance_image_offer" {
  description = "The 'offer' attribute of the OS image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "instance_image_sku" {
  description = "The 'sku' attribute of the OS image"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "instance_image_version" {
  description = "The 'version' attribute of the OS image"
  type        = string
  default     = "latest"
}

variable "instance_root_volume_size" {
  description = "The size of the root volume in gigabytes"
  type        = number
  default     = 128 # in GB
}

variable "instance_size" {
  description = "The size (type) of Azure instance to create. Must be an NC series size"
  type        = string
  default     = "Standard_NC6s_v2"
}

variable "network_address_space" {
  description = "A list of cidr values to define the address space in the resource group"
  type        = list
  default     = ["10.0.0.0/24"]
}

variable "subnet_address_prefixes" {
  description = "A list of cidr values to define the available address prefixes for the subnet"
  type        = list
  default     = ["10.0.0.0/29"]
}

variable "ssh_port_access" {
  description = "Access mode for ssh rule.  Allow or Deny. Applies to source and destination addresses"
  type = string
  default = "Allow"
}

variable "ssh_source_port_range" {
  description = "The source port range for ssh (port 22) connections to the instance"
  type = string
  default = "*"
}

variable "ssh_source_address_prefixes" {
  description = "The source address prefix for ssh (port 22) connections to the instance"
  type = list
  default = ["0.0.0.0/0"]
}

variable "ssh_destination_address_prefix" {
  description = "The destination address prefix for ssh (port 22) connections to the instance"
  type = string
  default = "*"
}

variable "triton_port_access" {
  description = "Access mode for triton rule.  Allow or Deny. Applies to source and destination addresses"
  type = string
  default = "Allow"
}

variable "triton_source_port_range" {
  description = "The source port range for triton server (ports 30000,30001,30002) connections to the instance"
  type = string
  default = "*"
}

variable "triton_source_address_prefixes" {
  description = "The source address prefix for triton server (ports 30000,30001,30002) connections to the instance"
  type = list
  default = ["0.0.0.0/0"]
}

variable "triton_destination_address_prefix" {
  description = "The destination address prefix for triton server (ports 30000,30001,30002) connections to the instance"
  type = string
  default = "*"
}

variable "user" {
  description = "The default user account for the instance"
  type        = string
  default     = "azureuser"
}

variable "public_key_path" {
  description = "The path of the public key file to use for ssh"
  type        = string
}

variable "private_key_path" {
  description = "The path of the private key file to use for ssh"
  type        = string
}

variable "resource_group_location" {
  description = "Location of the resource group."
  type        = string
  default     = "eastus"
}

variable "resource_group_prefix" {
  description = "Resource group prefix which will be combined with a random id."
  type        = string
  default     = "triton"
}

variable "azure_storage_account" {
  description = "The name of the azure storage account holding the model repository"
  type        = string
}

variable "azure_storage_key" {
  description = "The key for the azure storage account holding the model repository"
  type        = string
}

variable "model_repository" {
  description = " "
  type = string
}
