#!/bin/bash

set -uo pipefail ## Set Error handling so script fails safely.

HOME=`sudo grep $(logname) /etc/passwd | awk -F: '{print $6}'` # Set HOME folder of user invoking the script.

PWD=$(pwd) # We want to set the folder the script is run from  as a variable, for later usage in the script.
USER=$(logname)
if (( $EUID != 0 )); then # Because our script requires root privileges we need to check if the script is run as root. If not, the script should fail$
    echo "Please run this script as root. (sudo ./installer.sh)"
    exit 1
fi

### Here we confirm user has indeed configured the creds.tf file with accurate AWS keys.
read -p "Did you modify the devops2/terraform/creds.tf file to contain your up to date AWS credentials? (y/n)" choice

case "$choice" in 

  y|Y ) echo "script will start";;

  n|N ) echo " Please modify creds.tf in terraform folder before proceeding " 
       exit 1
;;

  * ) echo "invalid";;

esac


# Here we choose the distro so we know which play to invoke later on in script.

echo " Are you running redhat or ubuntu? Please type redhat or ubuntu"
echo
read -p "  Distro:  " OS
echo

# This is where we get the password for jenkins from the user input. We store it as a variable to pass on to our jenkins configure script later.
echo " What would you like the password for jenkins user 'jenkins' to be? (text hidden)"
echo
read -sp "  Jenkins Password:  " PASS
echo 

# Here we make the script pick the right OS block for installation.
case $OS in

redhat)
# This is where we install Ansible, git and expect for Redhat
sudo yum update -y
sudo yum install epel-release -y && sudo yum install ansible -y
sudo yum install git expect -y
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

ansible-playbook $HOME/devops2/playbooks/redhat-jenkins.yaml
if [ $? = 0 ]; then
echo "Ansible Playbook 'redhat-jenkins.yaml has installed jenkins!'"
echo "Ansible Playbook 'redhat-jenkins.yaml has installed jenkins!'" >> $HOME/devops2/installer.sh.log
else 
echo "Something went wrong running redhat-jenkins.yaml playbook"
echo "Something went wront running redhat-jenkins.yaml playbook" >> $HOME/devops2/installer.sh.log

fi

;;


ubuntu)
# This is where we install ansible, expect and git for ubuntu
sudo apt update
sudo apt install -y software-properties-common 
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
sudo apt install -y git expect 

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

ansible-playbook $HOME/devops2/playbooks/ubuntu-jenkins.yaml

if [ $? = 0 ]; then
echo "Ansible Playbook 'redhat-ubuntu.yaml has installed jenkins!'"
echo "Ansible Playbook 'redhat-ubuntu.yaml has installed jenkins!'" >> $HOME/devops2/installer.sh.log
else 
echo "Something went wrong running ubuntu-jenkins.yaml playbook"
echo "Something went wront running ubuntu-jenkins.yaml playbook" >> $HOME/devops2/installer.sh.log

fi

;;


*)
echo "Usage of script is as follows: 'sudo ./installer.sh, type redhat/ubuntu' so for redhat release use; 'sudo ./installer.sh redhat' and for ubuntu use 'sudo ./installer.sh ubuntu' "
exit 0
;;

esac

## This is where we set up AWS Instance using Terraform, and set up SSH and Ansible configuration so we can use Ansible on AWS Instance later on.


mkdir $HOME/.ssh/ # make sure folder .ssh exists
chown $USER $HOME/.ssh/  # set owner and group to user instead of root 
chgrp $USER $HOME/.ssh/

touch $HOME/.ssh/known_hosts # Same for known hosts.
chown $USER $HOME/.ssh/known_hosts
chgrp $USER $HOME/.ssh/known_hosts
chmod 644 $HOME/.ssh/known_hosts

echo ".ssh folder is set up and populated with (empty) known hosts file"
echo ".ssh folder is set up and populated with (empty) known hosts file" >> $HOME/devops2/installer.sh.log

cd $HOME/devops2/terraform/

# Here we call terraform to init, plan and apply inside terraform directory.
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


# This is where we add the terraform created host to the ansible inventory.
sudo echo "[ec2]
ec2-ansible ansible_host=`/usr/bin/terraform output -raw instance_public_ip` ansible_user=ec2-user remote_user=ec2-user ansible_ssh_private_key_file=$HOME/.ssh/thekey.pem" > /etc/ansible/hosts
# Here we add the IP Address and username + SSH key for the newly created EC2 Instance to the ansible hosts file, so we are able to connect to it. 
echo " Ansible inventory edited to contain EC2 Instance "
echo " Ansible inventory edited to contain EC2 Instance " >> $HOME/devops2/installer.sh.log

#### Making sure keyfile is set correctly to user.
sudo chown $USER $HOME/.ssh/thekey.pem # Because of Sudo/Root invocation the keyfile is now owned by root. We need to change this to the user that runs the script. 
sudo chgrp $USER $HOME/.ssh/thekey.pem # Set group to users group.
sudo chmod 600 $HOME/.ssh/thekey.pem # Here we set the permissions for the keyfile to be only rw for the owner, to prevent security issues, and make it easier for ansible to work with the file. 

echo " Sleeping for 30 seconds to give EC2 Instance time to properly initialize. (or ssh might not be ready) "
sleep 30s # Put the script to sleep for 0.5 minute 

#### First attempt to add fingerprints for non-prompt SSH access. 
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

##### This is where we invoke expect to pass our password to the playbook that takes care of jenkins configuration.
$HOME/devops2/config-scripts/expect/expect.sh $PASS $HOME

if [ $? = 0 ]; then
echo " Jenkins service is configured, "
echo " Jenkins service is configured " >> $HOME/devops2/installer.sh.log
else
echo "jenkins-config.yaml did not run correctly"
echo "jenkins-config.yaml did not run correctly" >> $HOME/devops2/installer.sh.log

fi

##### Running extra SSH / Jenkins permissions modification. Needed to set everything right. 
ansible-playbook $HOME/devops2/playbooks/jenkins-permissions.yaml
source $HOME/devops2/config-scripts/jenkins-ssh-settings.sh

if [ $? = 0 ]; then
echo " Jenkins SSH settings configured to allow ansible playbooks te be deployed on EC2 host "
echo " Jenkins SSH settings configured to allow ansible playbooks te be deployed on EC2 host " >> $HOME/devops2/installer.sh.log
else 
echo " Jenkins ssh-settings.sh did not run correctly "
echo " Jenkins ssh-settings.sh did not run correctly " >> $HOME/devops2/installer.sh.log

fi

##### Two more expect invoke's for ansible plays that connect using SSH. Expect is to fix adding fingerprints if it has not been done yet. 
###### $HOME variable is always passed along for correct directory structure / finding.
##### Expect2 runs ansible tomcat installation playbook.
##### Expect3 runs SSH configuration playbook and is the last script we run.

$HOME/devops2/config-scripts/expect/expect2 $HOME
echo expect2 script finished
$HOME/devops2/config-scripts/expect/expect3 $HOME
echo expect3 script finished 
if [ $? = 0 ]; then
echo " Tomcat has been installed, and is ready to receive WAR file for deployment on EC2 instance "
echo " Tomcat has been installed, and is ready to receive WAR file for deployment on EC2 instance " >> $HOME/devops2/installer.sh.log
else
echo " Tomcat playbook tomcat-ec2.yaml did not run correctly "
echo " Tomcat playbook tomcat-ec2.yaml did not run correctly " >> $HOME/devops2/installer.sh.log

fi

#### Here we tell the user how to work the magic using localhost:8080 to auto-import jobs, and send out the war file automatically. 
echo " Environment is set up correctly. Browse to localhost:8080 and click the build button on the seed job, after build is complete click the build button on the WAR file project. After build is done WAR is automaticly deployed to tomcat. See `/usr/bin/terraform output -raw instance_public_ip`:8080/webapp for the results " 
echo " Environment is set up correctly. Browse to localhost:8080 and click the build button on the seed job, after build is complete click the build button on the WAR file project. After build is done WAR is automaticly deployed to tomcat. See `/usr/bin/terraform output -raw instance_public_ip`:8080/webapp for the results " >> $HOME/devops2/installer.sh.log 


exit 0

