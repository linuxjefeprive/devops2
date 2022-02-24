#AWS EC2 Instance Provisioning project 

terraform {

  required_providers {

    aws = {         # this is where we set software requirements, so our software is the right version, otherwise code may be too new, or old for it to run properly. 

      source  = "hashicorp/aws"

      version = "~> 3.27"

    }

  }


  required_version = ">= 0.14.9"

}




resource "aws_instance" "projectec2" {

     ami = "ami-0ed9277fb7eb570c9" # this is where i configure the vm, using key and security group defined in keygen.tf and security.tf 

     instance_type = "t2.micro"
     
     key_name      = "thekey" #This is where we use the key made by keygen.tf to create the instance, so we can later log in using SSH and an exported keyfile. 

     associate_public_ip_address = "true" # Making sure the public IP is given, redundant, but i'm still putting it in there because it goes well with the security_groups option

     security_groups = [aws_security_group.security_group.name] # This uses the security group that terraform will create using the configuration in security.tf

  tags = { # Just some tags

    Name        = "ec2project"

    Environment = "development"


}


lifecycle {

     ignore_changes = [ami] # Ignore any changes made in ami! 

     }
}
