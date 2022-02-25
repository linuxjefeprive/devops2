#!/usr/bin/expect

set timeout -1
set password [lindex $argv 0]
set HOME [lindex $argv 1]

spawn ansible-playbook $HOME/devops2/playbooks/jenkins-config.yaml

expect "be?:" { send "$password\r" }
expect "*continue connecting*" { send "yes\r" }
