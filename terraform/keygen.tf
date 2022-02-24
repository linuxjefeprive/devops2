#This script is to make a keypair public/private and set the key-pair into aws. 

variable "key_name" {
type = string
default = "thekey" 
} 
# The keyname can be changed or set to user input if needed.


# use the tls_private_key module to generate a private key, RSA4096
resource "tls_private_key" "pk" {

  algorithm = "RSA"

  rsa_bits  = 4096

}



resource "aws_key_pair" "thekey" {

  key_name   = "thekey"  # Create a key named "thekey"

  public_key = tls_private_key.pk.public_key_openssh 
# Derive a public key to use with the VM's 


# Make sure the private key is saved locally to allow for loging in, especially to allow ansible to login without password. 
  provisioner "local-exec" { # Create a local copy of the private key named "thekey.pem"

    command = "echo '${tls_private_key.pk.private_key_pem}' > `sudo grep $(logname) /etc/passwd | awk -F: '{print $6}'`/.ssh/thekey.pem " # Export the key to the home/.ssh/ folder, for easy access using ansible. 
  }

}

