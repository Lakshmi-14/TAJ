provider "aws" {
  region     = "ap-northeast-1"
  access_key = "AKIA52XUGUQJXIRC65GY"
  secret_key = "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"
}


resource "aws_vpc" "main_vpc" {
  cidr_block       = "10.0.0.0/26"
  instance_tenancy = "default"

  tags = {
    Name = "Project_VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MyIGW"
  }
}

resource "aws_route" "routeIGW" {
  route_table_id            = aws_vpc.main_vpc.main_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}

resource "aws_subnet" "pub_a" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/26"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "Public_subnet_a"
  }
}



resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "ansible-instance" {
  ami             = "ami-0590f3a1742b17914"
  instance_type   = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.allow_all.id
  ]

  subnet_id = aws_subnet.pub_a.id
  associate_public_ip_address = true
  user_data = "${file("ansible.sh")}"
  key_name = "${aws_key_pair.new_key.id}"
  
  tags = {
    "Name" = "ansible-instance"
  }
}

resource "aws_instance" "jenkins-instance" {
  ami             = "ami-0590f3a1742b17914"
  instance_type   = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.allow_all.id
  ]

  subnet_id = aws_subnet.pub_a.id
  associate_public_ip_address = true
  #user_data = "${file("ansible.sh")}"
  key_name = "${aws_key_pair.new_key.id}"
  
  tags = {
    "Name" = "jenkins-instance"
  }
}

resource "aws_key_pair" "new_key" {
  key_name = "new-key"
  public_key = "${file("./credentials/new-key.pub")}"
}

output "Ansible-PublicIP" {
      value="${aws_instance.ansible-instance.public_ip}"
}
output "Ansible-PrivateIP" {
      value="${aws_instance.ansible-instance.private_ip}"
}
output "jenkins-PublicIP" {
      value="${aws_instance.jenkins-instance.public_ip}"
}
output "jenkins-PrivateIP" {
      value="${aws_instance.jenkins-instance.private_ip}"
}

