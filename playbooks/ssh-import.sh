#!/bin/bash
cat /home/ec2-user/jenkins-key.pub >> /home/ec2-user/.ssh/authorized_keys 1&2>/home/ec2-user/log.log
exit 0
