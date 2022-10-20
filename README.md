# Triton Inference Server Cloud Deployment Scripts

Convenience scripts for deploying a VM running Triton Inference Server in AWS or Azure

## General

The setup scripts for AWS and Azure use Terraform to build a new VM in the cloud.

Terminology:

* `Triton server` or `server` means the machine that will run Triton Inference Server
* `build host` means a Linux machine where cloud scripts are run to create a Triton server
* `cloud shell` means a Linux shell that is available from the console in AWS or Azure, and which is integrated with your account

You may use a Linux machine or WSL2 as a build host. If you do not have access to a Linux machine or WSL2, you may use a cloud shell as a build host.

See the additional README files in the [aws](aws/) and [azure](azure) subdirectories for some cloud-specific details.

### Minimum Server Specs

The Terraform scripts for AWS and Azure have sane defaults but allow you to adjust details of the server.
The default instance built by these scripts has:

* 64GB root partition
* 4 CPU
* 8GB memory
* Ubuntu 22.04 OS
* ports 30000, 30001, 30002 open for Triton access and port 22 open for ssh access

## Using a Cloud Shell as the Build Host

Open a cloud shell for your chosen cloud: [AWS](https://docs.aws.amazon.com/cloudshell/latest/userguide/working-with-cloudshell.html) or [Azure](https://learn.microsoft.com/en-us/azure/cloud-shell/overview).

The Azure shell has Terraform pre-installed. For AWS, the [instructions here](https://learn.hashicorp.com/tutorials/terraform/install-cli) show how to install Terraform in AWS CloudShell. These instructions are included in the [aws-install-terraform.sh](aws/aws-install-terraform.sh) wrapper script.

Clone this repository in the cloud shell, then skip ahead to [Running the cloud scripts](#running-the-cloud-scripts).

## Using a Linux Machine as the Build Host

[Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) on your local machine.

Terraform uses cloud CLIs to communicate with the different clouds. Follow these links to install a CLI:

* [Amazon aws](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [Azure az](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

Authenticate the CLI to the cloud:

* [Amazon aws](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-prereqs.html) prerequisites and [Quickstart](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
  
* [Azure az](https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli?source=recommendations#how-to-sign-into-the-azure-cli)

## Running the cloud scripts

### Ensure ssh Keys Exist

A ssh key pair is required during installation. Check to see if you already have a key pair available. (A key pair is usually made up of two files having the same name, one of which has the extension *.pub* and one of which has no extension)

```bash
$ ls ~/.ssh/
id_rsa id_rsa.pub
```

If you do not have a key pair available, you can create one like this

```bash
$ ssh-keygen -t RSA -b 4096
```

### Navigate to the Cloud Subdirectory

The cloud scripts will always be run from the subdirectories containing cloud-specific configuration files

```bash
$ cd cloud-scripts/aws # or azure
```

You must initialize Terraform the first time you use it from a particular directory
```bash
$ terraform init
```

### Set Required Values

Each cloud directory contains two settings files:

* `variables.tf` holds variable definitions
* `terraform.tfvars` is used to set values

Required values are listed in *terraform.tfvars*. If you do not set them, the script will prompt you for them.

### Creating the Triton Server

From your chosen cloud subdirectory, run `build-triton-server.sh`. When it completes the script will print summary information that you can use to ssh to the server, along with the Triton url(s)

```bash
$ ./build-triton-server.sh
...
outputs = {
  "ip" = "34.75.2.43"
  "machine" = "triton-merry-cobra"
  "private_key_path" = "~/.ssh/id_rsa"
  "user" = "tmckay"
}
The triton server http port is 34.75.2.43:30000
The triton server grpc port is 34.75.2.43:30001
The triton server metrics port is 34.75.2.43:30002
```

### Deleting the Triton Server

From your chosen cloud subdirectory, run `teardown-triton-server.sh`

```bash
$ ./teardown-triton-server.sh
```

### Configuration Options

### Restricting Network Access 

By default, access is unrestricted to ssh and the Triton ports on the server. The following values in the *terraform.tfvars* files can be used to restrict access to those ports. It is recommended that you restrict access to trusted addresses.

* AWS

  * `ssh_cidr_blocks`
  * `triton_server_cidr_blocks`

* Azure

  * `ssh_source_address_prefixes`
  * `triton_source_address_prefixes`

Each of the variables above takes a list of CIDR blocks as a value (Azure also allows IP addresses in the list).

#### Allowing ssh Access from the Build Host

Note that if you configure restricted access, you **must** allow ssh access from the build host or installation will fail.

For example, if the IP address of your build host is 20.47.56.12, include that  IP address in the list of addresses granted ssh access in *terraform.tfvars*
```bash
ssh_cidr_blocks = ["20.47.56.12/32", ...] # on AWS

ssh_source_address_prefixes = ["20.47.56.12", ...] # on Azure
```

#### Allowing ssh Access when the Build Host is a Cloud Shell

A cloud shell's public IP address is not immediately apparent.
To find it, use a service like *ifconfig.co* from the shell
```
$ curl ifconfig.co
34.148.241.75
```

Include the cloud shell's IP address in the ssh CIDR block variable in *terraform.tfvars* as described above.

Note that the same cloud shell may be given a new IP address each time you open it. If you need to re-establish ssh access for a cloud shell after the Triton server has been created, you can edit the firewall rules in the cloud console for your server to include the new IP address for the cloud shell (and remove the old one).

#### Allowing ssh Access from Another Host

To allow ssh access from a host other than the build host:

* Before building the Triton server, include the IP address of the other host in the ssh CIDR block variable in *terraform.tfvars* as described above

* After the Triton server is created, ssh into the server from the build host

* Choose a ssh key pair on the other host, or create a new one. Open the public key file from the pair and copy its contents.

* Edit the `~/.ssh/authorized_keys` file on the server and paste the new public key contents into the file on a new line

### Running more than one Triton server on the same cloud

Terraform will track resources that it creates and destroys in the directory where it is run. This means that each directory is tied to at most a single machine. If you would like to run more than one instance of Triton on the same cloud, you should copy the `*.tf` and `*.tfvars` files for that cloud and the bash scripts to another directory. For example

```bash
$ mkdir aws_two
$ cp aws/*.tf aws/*.tfvars aws_two aws/*-triton-server.sh
$ cd aws_two
```

## Managing the Triton Server

### Shutting down the Triton service temporarily

From the server
```bash
$ kubectl scale deployment --all --replicas=0 -n triton
```

To restart the service
```bash
$ kubectl scale deployment --all --replicas=1 -n triton
```

### Shutting down the Triton server

If you are going to shutdown the Triton server and restart it at a later date, follow this procedure.

From the server

```bash
kubectl scale deployment --all --replicas=0 -n triton
Kubectl get pods -n triton # wait until no pods are reported
```

Now the server may be shutdown.

Restart Triton when the server is restarted

```bash
$ scripts/wait-cnc.sh # waits for cloud-native-core to complte restart
$ kubectl scale deployment --all --replicas=1 -n triton
```

## Troubleshooting

If you cannot connect to the Triton service, here are some things to try.

### Check the installation logs

Login to the server. Check the files in the `logs` directory for any reported errors.

### Check localhost connections to Triton

From the server

```bash
curl -s -o /dev/null -w '%{http_code}\n' localhost:30000/v2/health/ready
200
```

If curl returns `200` but you can't connect to the service from another machine, check the firewall rules for the server in the cloud console.

### Check the status of cloud-native-core

From the server

```bash
$ kubectl get pods -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-6799f5f4b4-mnt9m   1/1     Running   0          91m
calico-node-fmb8l                          1/1     Running   0          91m
coredns-6d4b75cb6d-56rz2                   1/1     Running   0          90m
coredns-6d4b75cb6d-l6qhl                   1/1     Running   0          90m
etcd-cuopt-local3                          1/1     Running   0          91m
kube-apiserver-cuopt-local3                1/1     Running   0          91m
kube-controller-manager-cuopt-local3       1/1     Running   0          91m
kube-proxy-f445w                           1/1     Running   0          91m
kube-scheduler-cuopt-local3                1/1     Running   0          91m

$ kubectl get pods -n nvidia-gpu-operator
NAME                                                              READY   STATUS      RESTARTS   AGE
gpu-feature-discovery-wjrmw                                       1/1     Running     0          90m
gpu-operator-1663594758-node-feature-discovery-master-6fc72rxrp   1/1     Running     0          91m
gpu-operator-1663594758-node-feature-discovery-worker-x5f5m       1/1     Running     0          90m
gpu-operator-6d7dc7cfc-28r4v                                      1/1     Running     0          91m
nvidia-container-toolkit-daemonset-kmphs                          1/1     Running     0          90m
nvidia-cuda-validator-fv7pb                                       0/1     Completed   0          86m
nvidia-dcgm-exporter-9r7ts                                        1/1     Running     0          90m
nvidia-device-plugin-daemonset-92bxs                              1/1     Running     0          90m
nvidia-device-plugin-validator-sq4p6                              0/1     Completed   0          85m
nvidia-driver-daemonset-bf2sd                                     1/1     Running     0          90m
nvidia-operator-validator-jmbvh                                   1/1     Running     0          90m
```

The output should look similar to the above. If you see pods with error states,
or there appear to be pods missing, cloud-native-core may not have installed properly.

Destroy the machine and rerun the build script from the build host
  ```bash
  $ ./teardown-triton-server.sh
  $ ./build-triton-server.sh
  ```
