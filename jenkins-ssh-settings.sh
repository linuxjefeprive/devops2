#!/bin/bash
HOME=`sudo grep $(logname) /etc/passwd | awk -F: '{print $6}'` # Set HOME folder invoking script
USER=$(logname) 
if (( $EUID != 0 )); then
echo "Please run as Root " 
echo "Please Run as Root" > errorlog.log
fi 

# Adding known hosts to Jenkins folder 
sudo cp $HOME/.ssh/known_hosts /var/lib/jenkins/.ssh/known_hosts

# Add a Jenkins specific inventory entry into Ansible 
sudo cat /etc/ansible/hosts > adjust && sed -i 's/ec2/ec2-jenkins/g' adjust && sed -i 's/ansible_ssh.*/ansible_ssh_private_key_file=\/var\/lib\/jenkins\/.ssh\/jenkins-key/g' adjust
cat adjust | sudo tee -a /etc/ansible/hosts 
rm adjust


