# provider section
variable "access_key" {}
variable "access_secret" {}
variable "public_key" {}
#variable "private_key_pem" {}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.access_secret
}

# VPC section
#resource "aws_vpc" "hg-vpc" {
#  cidr_block = "10.0.0.0/16"
#  tags = {
#    Name = "hangout-web"
#  }
#}

#resource "aws_subnet" "subnet-0" {
#  vpc_id            = aws_vpc.hg-vpc.id
#  cidr_block        = "10.0.1.0/24"

#  tags = {
#    Name = "hangout prod subnet"  }
#}

# End of VPC section

# Security group section

resource "aws_security_group" "allow_SSH" {
  name        = "allow_SSH"
  description = "Allow SSH inbound traffic"
  #vpc_id      = aws_vpc.default

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "HTTP-Jen"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
   description = "HTTP-Docker-API"
   from_port   = 4200
   to_port     = 4400
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }

 ingress {
  description = "HTTP-Docker-hostport"
  from_port   = 32768
  to_port     = 60999
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }



  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# End of security group section


# Jenkins instance creation section

resource "aws_key_pair" "deployer4" {
  key_name   = "deployer4"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLbr9ATK0QLXbQb4apk2iX2/XT8Hq9ON1XQZWJQlnjIvP5QBWryUy2kpfJJgfLJ5FC3wl3OGA9Y/4lDBlwCd0+SRA+k+tL7F5J6A8Nu42qvKeWPVYlgEz5lkNhFZcpJazKP0vcVTGfj2So0iGU9RQqGgH2AU04ncIXuO/0DErvDx7ZXYcEtrV3c+3yasgdJFkS0sTJ4eMsEwHp0e8eHD1k4xYo69RK+6FUYfu4WzTRwSteDuxJG06zO/s0Sh9J/SoyN43R+TDpw5jXVsjwcF+p66rst3RgGbSTC4+HuhyyPKN8piEHQCOeQ4o8mzRL6yy84q4JoD79IkL6JNgzh+19A/mXHxm5uGVIjhgk48by0UItQUDwziruhn9zYcHz6CGcqgylhCXR+zbYJYmtqO4qb7gQd0ROZbmDI8+vc2qTrhpT39DbmSOwAR54nklMNIL5WeXJy9M3lywgbUVgYUm1pL2oG/O0SMl66Ncd3lxK8eIVtfQPmu45e0RaagdaUSE= dsc@pop-os"
  }



resource "aws_instance" "jenkins-controller" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer4.key_name
  #vpc_id      = aws_vpc.hg-vpc.id
  vpc_security_group_ids = ["${aws_security_group.allow_SSH.id}"]
  tags = {
    "Name" = "Jenkins Controller"
    "ENV"  = "Prod"
  }

  depends_on = [aws_key_pair.deployer4]

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
      "echo starting installation from NOW",
      "sudo wget -O- https://apt.corretto.aws/corretto.key | sudo apt-key add -",
      "sudo add-apt-repository 'deb https://apt.corretto.aws stable main'",
      "sudo apt-get update",
      "sudo apt-get install -y java-17-amazon-corretto-jdk",
      "echo JAVA installed",
      "sudo apt-get install -y ttf-dejavu",
      "sudo apt-get install -y fontconfig",
      "sudo apt install -y python3.8",
      "echo PYHTON installed",
      "curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
      "sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null'",
      "sudo apt-get update",
      "sudo apt-get install -y jenkins",
      "echo JENKINS installed",
      #"sudo apt install net-tools",
      "sudo hostnamectl set-hostname jenkins-c",
      #"ifconfig",
    ]
  }
}



resource "aws_instance" "docker-node" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer4.key_name
  #vpc_id      = aws_vpc.hg-vpc.id
  vpc_security_group_ids = ["${aws_security_group.allow_SSH.id}"]
  tags = {
    "Name" = "Docker Node"
    "ENV"  = "Prod"
  }
depends_on = [aws_key_pair.deployer4]
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
      "sudo apt update",
      "sudo wget -O- https://apt.corretto.aws/corretto.key | sudo apt-key add -",
      "sudo add-apt-repository 'deb https://apt.corretto.aws stable main'",
      "sudo apt-get update",
      "sudo apt-get install -y java-17-amazon-corretto-jdk",
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sudo sh get-docker.sh",
      #"sudo apt install net-tools",
      "sudo hostnamectl set-hostname docker-node",
      "echo 42",
      #"ifconfig",
    ]
  }
}
