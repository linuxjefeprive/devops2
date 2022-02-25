#!/bin/bash

set -uo pipefail ## Set Error handling so script fails safely.

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
sudo yum update -y
sudo yum install epel-release -y && sudo yum install ansible -y
sudo yum install git -y
# Now we install terraform for redhat, so we can automaticly setup a remote tomcat server on aws later, this is easier in terraform than in ansible.
sudo yum install -y yum-utils
sudo yum-config-manager -y --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install -y terraform

if [ $? = 0 ]; then
echo "Terraform and Ansible are installed!"
echo "Terraform and Ansible are installed!" > $HOME/devops2/installer.sh.log
else 
echo "Something went wront Installing Terraform or Ansible"
echo "Something went wront Installing Terraform or Ansible" > $HOME/devops2/installer.sh.log

fi

ansible-playbook $HOME/devops2/redhat-jenkins.yaml
if [ $? = 0 ]; then
echo "Ansible Playbook 'redhat-jenkins.yaml has installed jenkins!'"
echo "Ansible Playbook 'redhat-jenkins.yaml has installed jenkins!'" >> $HOME/devops2/installer.sh.log
else 
echo "Something went wrong running redhat-jenkins.yaml playbook"
echo "Something went wront running redhat-jenkins.yaml playbook" >> $HOME/devops2/installer.sh.log

fi

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



if [ $? = 0 ]; then
echo "Terraform and Ansible are installed!"
echo "Terraform and Ansible are installed!" > $HOME/devops2/installer.sh.log
else 
echo "Something went wront Installing Terraform or Ansible"
echo "Something went wront Installing Terraform or Ansible" > $HOME/devops2/installer.sh.log
fi 

ansible-playbook $HOME/devops2/ubuntu-jenkins.yaml

if [ $? = 0 ]; then
echo "Ansible Playbook 'redhat-ubuntu.yaml has installed jenkins!'"
echo "Ansible Playbook 'redhat-ubuntu.yaml has installed jenkins!'" >> $HOME/devops2/installer.sh.log
else 
echo "Something went wrong running ubuntu-jenkins.yaml playbook"
echo "Something went wront running ubuntu-jenkins.yaml playbook" >> $HOME/devops2/installer.sh.log

fi

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

touch $HOME/.ssh/known_hosts
chown $USER $HOME/.ssh/known_hosts
chgrp $USER $HOME/.ssh/known_hosts
chmod 644 $HOME/.ssh/known_hosts

echo ".ssh folder is set up and populated with (empty) known hosts file"
echo ".ssh folder is set up and populated with (empty) known hosts file" >> $HOME/devops2/installer.sh.log

cd $HOME/devops2/terraform/

/usr/bin/terraform init # using full path to binary because root on RPM does not include /usr/local/bin in PATH's  
/usr/bin/terraform plan 
/usr/bin/terraform apply -auto-approve

if [ $? = 0 ]; then
echo "'Terraform has set up our Remote EC2 node to run Tomcat on'"
echo "'Terraform has set up our Remote EC2 node to run Tomcat on'" >> $HOME/devops2/installer.sh.log
else 
echo "Terraform failed to set up EC2 instance, check creds.tf, and make sure AWS is clean"
echo echo "Terraform failed to set up EC2 instance, check creds.tf, and make sure AWS is clean" >> $HOME/devops2/installer.sh.log

fi



sudo echo "[ec2]
ec2-ansible ansible_host=`/usr/bin/terraform output -raw instance_public_ip` ansible_user=ec2-user remote_user=ec2-user ansible_ssh_private_key_file=$HOME/.ssh/thekey.pem" > /etc/ansible/hosts
# Here we add the IP Address and username + SSH key for the newly created EC2 Instance to the ansible hosts file, so we are able to connect to it. 
echo " Ansible inventory edited to contain EC2 Instance "
echo " Ansible inventory edited to contain EC2 Instance "

sudo chown $USER $HOME/.ssh/thekey.pem # Because of Sudo/Root invocation the keyfile is now owned by root. We need to change this to the user that runs the script. 
sudo chgrp $USER $HOME/.ssh/thekey.pem # Set group to users group.
sudo chmod 600 $HOME/.ssh/thekey.pem # Here we set the permissions for the keyfile to be only rw for the owner, to prevent security issues, and make it easier for ansible to work with the file. 

echo " Sleeping for 30 seconds to give EC2 Instance time to properly initialize. (or ssh might not be ready) "
sleep 30s # Put the script to sleep for 0.5 minute 

ssh-keyscan -H `/usr/bin/terraform output -raw instance_public_ip` >> $HOME/.ssh/known_hosts #Here we add the remote key fingerprint for automation.
sudo ssh-keyscan -H `/usr/bin/terraform output -raw instance_public_ip` >> $HOME/.ssh/known_hosts
sudo ssh-keyscan -H `/usr/bin/terraform output -raw instance_public_ip` >> ~/.ssh/known_hosts ## Also for sudo :) 

if [ $? = 0 ]; then
echo "SSH Keys are added for promptless connection"
echo "SSH Keys are added for promptless connection" >> $HOME/devops2/installer.sh.log
else 
echo "SSH keys could not be added"
echo "SSH keys could not be added" >> $HOME/devops2/installer.sh.log

fi 



echo " All done, `/usr/bin/terraform output -raw instance_public_ip` added to ansible inventory under hostgroup ec2, keyfile saved in $HOME/.ssh/thekey.pem,"
echo " All done, `/usr/bin/terraform output -raw instance_public_ip` added to ansible inventory under hostgroup ec2, keyfile saved in $HOME/.ssh/thekey.pem " >> $HOME/devops2/installer.sh.log

ansible-playbook $HOME/devops2/jenkins-config.yaml

if [ $? = 0 ]; then
echo " Jenkins service is configured, "
echo " Jenkins service is configured " >> $HOME/devops2/installer.sh.log
else
echo "jenkins-config.yaml did not run correctly"
echo "jenkins-config.yaml did not run correctly" >> $HOME/devops2/installer.sh.log

fi


source $HOME/devops2/jenkins-ssh-settings.sh

if [ $? = 0 ]; then
echo " Jenkins SSH settings configured to allow ansible playbooks te be deployed on EC2 host "
echo " Jenkins SSH settings configured to allow ansible playbooks te be deployed on EC2 host " >> $HOME/devops2/installer.sh.log
else 
echo " Jenkins ssh-settings.sh did not run correctly "
echo " Jenkins ssh-settings.sh did not run correctly " >> $HOME/devops2/installer.sh.log

fi


ansible-playbook $HOME/devops2/tomcat-ec2.yaml

if [ $? = 0 ]; then
echo " Tomcat has been installed, and is ready to receive WAR file for deployment on EC2 instance "
echo " Tomcat has been installed, and is ready to receive WAR file for deployment on EC2 instance " >> $HOME/devops2/installer.sh.log
else
echo " Tomcat playbook tomcat-ec2.yaml did not run correctly "
echo " Tomcat playbook tomcat-ec2.yaml did not run correctly " >> $HOME/devops2/installer.sh.log

fi

echo " Environment is set up correctly. Browse to localhost:8080 and click the build button on the seed job, after build is complete click the build button on the WAR file project. After build is done WAR is automaticly deployed to tomcat. See `/usr/bin/terraform output -raw instance_public_ip`:8080/webapp for the results " 
echo " Environment is set up correctly. Browse to localhost:8080 and click the build button on the seed job, after build is complete click the build button on the WAR file project. After build is done WAR is automaticly deployed to tomcat. See `/usr/bin/terraform output -raw instance_public_ip`:8080/webapp for the results " >> $HOME/devops2/installer.sh.log 


exit 0

