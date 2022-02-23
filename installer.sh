#!/bin/bash

case $1 in

redhat)
# This is where we install Ansible and git for Redhat
sudo yum update
sudo yum install epel-release && sudo yum install ansible
sudo yum install git -y
# Now we install terraform for redhat, so we can automaticly setup a remote tomcat server on aws later, this is easier in terraform than in ansible.
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install -y terraform
;;


ubuntu)
# This is where we install ansible and git for ubuntu
sudo apt update
sudo apt install -y software-properties-common 
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
sudo apt install -y git

## Now we install Terraform in Ubuntu so we can create a tomcat aws instance easily later.
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

;;


*)
echo "Usage of script is as follows: './installer.sh redhat/ubuntu' so for redhat release use; './installer.sh redhat' and for ubuntu use './installer.sh ubuntu' "
;;

esac
exit 0

