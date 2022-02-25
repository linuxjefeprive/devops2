#!/usr/bin/expect

set password [lindex $argv 0]
set HOME [lindex $argv 1]

spawn ansible-playbook $HOME/devops2/jenkins-config.yaml

expect "be?:" { send "$password\r" }

interact
