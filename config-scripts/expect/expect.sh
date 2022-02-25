#!/usr/bin/expect

set timeout 240
set password [lindex $argv 0]
set HOME [lindex $argv 1]

spawn ansible-playbook $HOME/devops2/playbooks/jenkins-config.yaml

expect "be?:" { send "$password\r" }
expect "Are you sure you want to continue connecting (yes/no)? " { send "yes\r" }

interact
