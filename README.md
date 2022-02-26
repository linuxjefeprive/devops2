https://github.com/linuxjefeprive/devops2


This is my CalTech DevOps PGP Program Project for the PG DO - DevOps Certification Training. Project 1, CI/CD Deployment Using Ansible CM Tool.
The github folder is called devops2, because this is the second project I’m doing for the PG Devops program. Do note; this is project #1. 



##################################################################################

ASSIGNMENT DESCRIPTION


You are a DevOps engineer at XYZ Ltd. Your company is working on a Java application and wants to automate WAR file artifact deployment so that they don’t have to perform WAR deployment on Tomcat/Jetty web containers. Automate Ansible integration with Jenkins CI server so that we can run and execute playbooks to deploy custom WAR files to a web container and then perform restart for the web container.
 
Steps to Perform:
1.	Configure Jenkins server as Ansible provisioning machine
2.	Install Ansible plugins in Jenkins CI server
3.	Prepare Ansible playbook to run Maven build on Jenkins CI server
4.	Prepare Ansible playbook to execute deployment steps on the remote web container with restart of the web container post deployment


#######################################################################################

ACTUAL PROJECT 

########################################################################################


The assignment goals were reached with relative ease, which is why I decided to try taking this project to the next level, by fully automating everything from scratch, configuring and setting up everything with a single one click installer. My goal was to not use docker, but to install and configure everything from scratch using code. Because turning off security options would make this project easier, I decided to have my script handle everything with security on. The only exception is Jenkins script approval, which would not be needed anyway because in production script vetting would be done on/via github. I have completely automated everything, and there is no usage of the web UI or interaction during install what so ever. (except at the start of the script). The only thing we use the UI for is to press the “build” button after initial setup to seed the jobs from github, import the jobs automatically and execute the WAR build to deploy to our Tomcat instance. Usage of this script is relatively easy;

This repo is used, the other repo's used are https://github.com/linuxjefeprive/jenkins-seed Where I created the seed file for Jenkins, and https://github.com/linuxjefeprive/Hello-World-Code , which is the application that will be deployed to EC2 instance using jenkinsfile and ansible. 


##########################################################################################

INSTRUCTIONS AND EXPLANATION

##########################################################################################


Clone https://github.com/linuxjefeprive/devops2.git to your local HOME directory. The script is build to support RedHat and Ubuntu based distro’s, and has been tested and shown to run smoothly (no interaction needed after initial script setup) on Ubuntu 18.04, Ubuntu 20.04, Rocky Linux 8 and Simplilearn online environment. 


$ Cd devops2/terraform/      # adjust the creds.tf file to contain up to date AWS authentication keys.

$ Cd ..                      # to go into HOME/devops2 folder

$ sudo ./installer           # To start the installer.



The script will start and will first ask the user if he supplied the correct credentials for AWS in the creds.tf file. If you already did this please confirm. 
The script will ask the user if he is using Ubuntu or redhat distro. Please confirm your distro by answering the script. 
Last the script will ask the user how he would the password for Jenkins to be. User will always be named “jenkins”
The password is taken as a variable, and passed to “expect” script to be used later on automatically during the Jenkins configuration.



This will initiate the script, and perform the following actions; 

1: Script will install Terraform, Ansible, git and expect on local node. (Ubuntu / Redhat)

2: Script will use Ansible to install Jenkins on local node. Java and Maven will also be installed, and service will be ensured running. 

3: Terraform will run to set up a EC2 instance that we will later run tomcat server on. Keys, security groups and key exchange is all done fully automatically, and secure. EC2 Instance is also added to Ansible inventory automatically.

4: SSH keys and permissions are all set automatically

5: Ansible will run a playbook called Jenkins-config to configure Jenkins from the ground up. Username and password will be set, security and rules will be configured, standard plugins will be installed, extra Ansible, JCasC and JobDSL plugin will be installed. The playbook can of course be edited to contain any plugin required. After plugin installation Ansible will move our JCasC configuration file to the Jenkins folder. This file contains the configuration for Jenkins and our plugins. After the copying of configs the Jenkins server will restart and run our JCasC script to become fully configured. There is a “seed” job injected automatically, which is connected to my seed repository on github. My seed repository contains all the jobs we want Jenkins to import automatically. This is done by clicking “build” after login into localhost:8080 ( do this after the script is finished.) (For this example there is only one job in the seed repo; the maven WAR build).

6: The Jenkins configuration will need it’s own Jenkins SSH key and access to EC2 instance to be able to use Ansible plugin later on. The quick fix for this problem is making Jenkins ROOT, but this is unsafe, so I made the script configure Jenkins in such a way that it can run ansible scripts without any security problems. 

7: After Jenkins is completely set up, ansible will deploy Tomcat to our EC2 instance. This is also done completely automaticly. 

8: The script finishes and tells the user what webpage to go to to start the seed job, (localhost:8080). After clicking the build button for the seed job Jenkins will automatically add the jobs in the seed repo by linking to job repo’s on github. These repo’s contain jenkinsfile’s, so all configuration is done automatically. The script will also tell the user where to find the tomcat url. (ec2 instance:8080/webapp)

9: After the seed job has finished building, you will notice the WAR job has become available in Jenkins. Click the “build” button, to pull the files from github and start building. The ansible script is saved in the github folder as well, so everything will be done automatically. After the build is done you can browse to “ec2 instance:8080/webapp” to see the fruits of our labour. (address was given to you at end of installer script )

#######################################################################################

EXTRA INFO

#######################################################################################



If anything goes wrong, (hasn’t happened with the finished version on 4 different hosts with different OS’s so far!) there is a logfile created in devops2/ called installer.sh.log where actions are logged when finished or failed.   
This is how I’ve set up a Jenkins server completely automatically, from the ground up. Including plugins, jobs, permissions and configuration. The WAR deployment is done by simply clicking build, and is also completely automatic. In the future we would probably add webhooks to build on github push, and add other magic, but so far I’ve not found a way to set up webhooks completely automatic. (since github requires config settings). 


All code is commented in detail, so grading should be easy looking at the code. 


#######################################################################################

AFTERWORD

#######################################################################################

This project has been an amazing learning experience! I have learned a lot about automation, especially when it comes to Ansible and Jenkins. And i've learned that there are lots of ways to avoid using UI and do everything by CLI setting up services. Even setting up and configuring Jenkins completely from code which seemed impossible at first is completely possible!

In the future I want to expand on using Ansible vault, roles, and generally getting better at Ansible and Terraform. 

Thank you !

