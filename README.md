# mmp-paas

The **mmp-paas** project provides the capability to provision the various technologies that make up the PaaS platform in an automated manner using Packer, Vagrant and Ansible. Support is provided for the Virtualbox, VMware Fusion and vSphere virtualisation platforms.

## Usage

The config.yml file defines all the servers that make up the PaaS platform and the Ansible configuration that should be applied to these servers. The **profiles** section at the top of the **config.yml** file defines collections of servers that should be provisioned as a related unit. This allows a portion of the PaaS platform to be deployed using a command similar to the following:

vagrant --profile=<PROFILE NAME> up --provider=<PROVIDER NAME> --no-parallel

e.g.

vagrant --profile=paas_minimal up --provider=virtualbox --no-parallel

## Deploying on Windows

1. Download and install VirtualBox for Windows from https://virtualbox.org.

- Configure the VirtualBox Host-Only Ethernet Adapter as follows:

  ```
  Adapter:
    IPv4 Address: 192.168.100.1
    IPv4 Network Mask: 255.255.255.0
  
  DHCP Server:
    Enable Server: True
    Server Address: 192.168.56.100
    Server Mask: 255.255.255.0
    Lower Address Bound: 192.168.56.101
    Upper Address Bound: 192.168.56.254
    ```
    
- Download and install Git for Windows from https://git-scm.com/download/Windows.

- Download and install Packer for Windows from https://packer.io. You can extract the Packer binary in the ZIP to your C:\Windows folder or copy it to a different directory and make sure this directory is part of the PATH environment variable.

- Download and install Vagrant for Windows from https://www.vagrantup.com.

- Open a Git Bash terminal e.g. All apps > Git > Git Bash.

- Clone the https://github.com/marcusportmann/mmp-packer.git project.

- Execute the build-virtualbox.sh script under the mmp-packer directory.


