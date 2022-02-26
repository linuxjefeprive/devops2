#!/usr/bin/expect
#### This is an expect script that uses the jenkins password argument passed from installer.sh to put into Jenkins configuration. 
#### It also accepts adding fingerprint for the first time SSH connection
set timeout -1
set password [lindex $argv 0]
set HOME [lindex $argv 1]

spawn ansible-playbook $HOME/devops2/playbooks/jenkins-config.yaml

expect "be?:" { send "$password\r" }
expect "*continue connecting*" { send "yes\r" }
