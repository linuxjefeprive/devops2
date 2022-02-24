#!/bin/bash


HOME=`sudo grep $(logname) /etc/passwd | awk -F: '{print $6}'` # Set HOME folder of user invoking the script.

PWD=$(pwd) # We want to set the folder the script is run from  as a variable, for later usage in the script.
USER=$(logname)
if (( $EUID != 0 )); then # Because our script requires root privileges we need to check if the script is run as root. If not, the script should fail$
    echo "Please run this script as root. (sudo ./installer.sh)"
    exit 1
fi



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
echo "Usage of script is as follows: 'sudo ./installer.sh redhat/ubuntu' so for redhat release use; 'sudo ./installer.sh redhat' and for ubuntu use 'sudo ./installer.sh ubuntu' "
exit 0
;;

esac

## This is where we set up AWS Instance using Terraform, and set up SSH and Ansible configuration so we can use Ansible on AWS Instance later on.


mkdir $HOME/.ssh/ # make sure folder .ssh exists
chown $USER $HOME/.ssh/  # set owner and group to user instead of root 
chgrp $USER $HOME/.ssh/

cd $HOME/devops2/terraform/

/usr/bin/terraform init # using full path to binary because root on RPM does not include /usr/local/bin in PATH's  
/usr/bin/terraform plan 
/usr/bin/terraform apply -auto-approve

sudo echo "[ec2]
`/usr/bin/terraform output -raw instance_public_ip` ansible_user=ec2-user remote_user=ec2-user ansible_ssh_private_key_file=$HOME/.ssh/thekey.pem" > /etc/ansible/hosts
# Here we add the IP Address and username + SSH key for the newly created EC2 Instance to the ansible hosts file, so we are able to connect to it. 

sudo chown $USER $HOME/.ssh/thekey.pem # Because of Sudo/Root invocation the keyfile is now owned by root. We need to change this to the user that runs the script. 
sudo chgrp $USER $HOME/.ssh/thekey.pem # Set group to users group.
sudo chmod 600 $HOME/.ssh/thekey.pem # Here we set the permissions for the keyfile to be only rw for the owner, to prevent security issues, and make it easier for ansible to work with the file. 

echo " Sleeping for 30 seconds to give EC2 Instance time to properly initialize. (or ssh might not be ready) "

# Using ansible play to add keys now, better solution. 
#sleep 30s # Put the script to sleep for 0.5 minute 
#ssh -o "StrictHostKeyChecking no" ec2-user@`/usr/bin/terraform output -raw instance_public_ip` -i $HOME/.ssh/thekey.pem "exit"  #Here we add the remote key fingerprint for automation.
#sudo ssh -o "StrictHostKeyChecking no" ec2-user@`/usr/bin/terraform output -raw instance_public_ip` -i $HOME/.ssh/thekey.pem "exit" # We do the same for root 
sleep 5s

echo " All done, `/usr/bin/terraform output -raw instance_public_ip` added to ansible inventory under hostgroup ec2, keyfile saved in $HOME/.ssh/thekey.pem, Please invoke keyscan.yaml to add host to know_hosts  "

exit 0

