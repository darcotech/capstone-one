terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_security_group" "allow_SSH" {
  name        = "allow_SSH"
  description = "Allow SSH inbound traffic"
  #   vpc_id      = aws_vpc.main.id


  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    # description      = "SSH from VPC"
    # from_port        = 22
    # to_port          = 22
    # protocol         = "tcp"
    # cidr_blocks      = ["61.6.14.46/32"]
    # # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDL2g8Pyo/WdFXw001NsUcoa1qfNmCyVZW/IfA2wMPDG3R3QbLtGLgJ17lVXmGFsRseu3SPhsS3fDdG6PwlZo26PFvnZtSO+I92eJQqwfAq//d4epsrJMY82jWDmAoTxUuxFZ2ob11ohvqU59l6xtJp+NDl0rpd+/Pn7329HuB/vXlb4AtHNzdhWoeT9Tb1Wd4JVmZjf6YgRZl/NxyKEkCl/LKDRQCfeXGoQIqYLgSU09//Ll1xLp5Gh/Wdh8Pk1GLbGwGKgHsmOwsipeCd4ul8gOrt99gv2K31OWxCWZUkh2xKT9lOOrZ958uNZCVswD5lgwWmzZ5Q3jbhXti+LjrBuj9Ri+4fsleyjE7IWHvche2qz/CNQAR30CroDfmwo3KCj4XP0fyGgq2U0nAA+QRQqorZZSyJ09Nzl6QEHhNhMpufoeW426JhMHgSiJ+G8aAU68BAQj9VYxNt7N+bhubQKAicVXKqoLfzROZOJ6F2OiZ69D6ZkTKnt0TNHPpWIpc= dsoladarcotech@ip-172-31-31-29"
}



resource "aws_instance" "ubuntu" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = ["${aws_security_group.allow_SSH.id}"]
  tags = {
    "Name" = "UBUNTU-Node"
    "ENV"  = "Dev"
  }

  depends_on = [aws_key_pair.deployer]

  # Type of connection to be established
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./deployer")
    host        = self.public_ip
  }
  # Remotely execute commands to install Java, Python, Jenkins
  provisioner "remote-exec" {
    inline = [
      "sudo apt update && upgrade",
      "sudo apt install -y python3.8",
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ >  /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-8-jre",
      "sudo apt-get install -y jenkins",
    ]
  }

  

}