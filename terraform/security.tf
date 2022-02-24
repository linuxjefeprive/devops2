# This script sets up a security group for our instance, this is needed to allow ssh traffic, which we need to connect, manually and via ansible.

resource "aws_security_group" "security_group" {

  name = "security_group"


# Incoming traffic from all IP's on port 22/tcp is allowed.
  ingress {

    from_port   = 22

    to_port     = 22

    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

# Incoming traffic from all IP's on port 22/tcp is allowed.
  ingress {

    from_port   = 8080

    to_port     = 8080

    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }






  # Allow outgoing traffic to anywhere.

  egress {

    from_port   = 0

    to_port     = 0

    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}

