# mmp-paas

The **mmp-paas** project provides the capability to provision the various technologies that make up the PaaS platform in an automated manner using Packer, Vagrant and Ansible. Support is provided for the Virtualbox, VMware Fusion and vSphere virtualisation platforms.

## Usage

The config.yml file defines all the servers that make up the PaaS platform and the Ansible configuration that should be applied to these servers. The **profiles** section at the top of the **config.yml** file defines collections of servers that should be provisioned as a related unit. This allows a portion of the PaaS platform to be deployed using a command similar to the following:

vagrant --profile=<PROFILE NAME> up --provider=<PROVIDER NAME> --no-parallel

e.g.

vagrant --profile=paas_minimal up --provider=virtualbox --no-parallel

## Installation

1. Download and install VirtualBox from https://virtualbox.org.

2. Configure the VirtualBox Host-Only Ethernet Adapter as follows:

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

3. Install Git e.g. on CentOS execute **yum -y install git**.

4. Download and install Packer from https://packer.io.

5. Download and install Vagrant from https://www.vagrantup.com.

6. Open a Bash terminal.

7. Clone the https://github.com/marcusportmann/mmp-packer.git project.

8. Execute the build-virtualbox.sh script under the mmp-packer directory.

9. Follow the instructions on http://docs.ansible.com/ansible/intro_installation.html#installing-the-control-machine to install Ansible.

10. Clone the https://github.com/marcusportmann/mmp-paas.git project.

11. Execute the following command under the mmp-paas directory:

  vagrant --profile=paas_minimal up --provider=virtualbox --no-parallel

