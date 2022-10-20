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

# The following variables are required for AWS and have no defaults

private_key_path = "~/.ssh/id_rsa"
public_key_path = "~/.ssh/id_rsa.pub"

model_repository = "s3://tmckay-exp/model_repository"
model_repository_region = "us-east-2"

# Optional settings

# List of CIDR block values for addresses allowed to connect to the ssh port.
# If installing from a cloud shell, the public IP address of the cloud shell must be included here
# Individual IP addresses must be expressed as CIDRs in the form 1.2.3.4/32
#ssh_cidr_blocks = ["0.0.0.0/0"]

# List of CIDR block values for addresses allowed to connect to the server.
# Individual IP addresses must be expressed as CIDRs in the form 1.2.3.4/32
# More info at https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
#server_cidr_blocks = ["0.0.0.0/0"]

# Additional notes on CIDR blocks

# If your default network has default rules for port 22 that you would like to use instead,
# set this value to [] to prevent creation of the rule for port 22.
#ssh_cidr_blocks = []

# If your default network has default rules for ports 30000-30001 that you would like to use instead,
# set this value to [] to prevent creation of the rule for ports 30000-30001
#server_cidr_blocks = []

# If your default network has default rules for outgoing traffic that you would like to use instead,
# set this value to [] to prevent creation of the rule for outgoing traffic (default unrestricted)
#outgoing_cidr_blocks = []

# If your default network has existing security groups you would like to apply to this instance,
# list their names in this value
#additional_security_groups = ["my-security-group"]
