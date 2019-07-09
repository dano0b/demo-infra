terraform {
  backend "s3" {
    bucket = "terraform-state-demo-ekoapp"
    key    = "terraform-state"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "ap-southeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "main" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "route-association" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.route.id}"
}


resource "aws_security_group" "allow_incoming_http" {
  name        = "allow-incoming-demo"
  description = "Allow inbound HTTP traffic"
  vpc_id      = "${aws_vpc.main.id}"
}
resource "aws_security_group_rule" "ingress-http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.allow_incoming_http.id}"
}
resource "aws_security_group_rule" "ingress-https" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.allow_incoming_http.id}"
}

resource "aws_security_group" "allow_incoming_ssh" {
  name        = "allow_incoming_ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = "${aws_vpc.main.id}"
}
resource "aws_security_group_rule" "ingress-ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.allow_incoming_ssh.id}"
}

resource "aws_key_pair" "ansible" {
  key_name   = "ansible"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmQK8bnNKo8g0cXAMyOkzIcQ0PryrF6eF5xl94U7N5HwyCkuOgD74TOLSXRTxwLO3Ne0r2bQpdGMEWy00KAJiC0/tgGjCuhmjBn4YOBSbJOkwUZZjKn2JxlYHB/pvLLhe/DPvLFqMRRs+4H7rfo7oxrJR9frBKsWI/PhQvVT479bGKYO5y6VGSVbOtz21YmSZVYNVaWVCieo4FN2ySGADxfaiLdrm5dEDsoVwrAG8atud7Odu2rcxz0W+rYHscmBKsILd9w/0apGnUf4AzPWrbhNo1HCQIp033Um5KaemIz//nMnlMaBaGi7q0fQYqrD1PVuJC/d6R7yPkVLT0rodL ansible"
}

resource "aws_instance" "web" {
  ami           = "ami-0bb35a5dad5658286"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_incoming_ssh.id}","${aws_security_group.allow_incoming_http.id}"]
  key_name = "${aws_key_pair.ansible.key_name}"
  depends_on = ["aws_internet_gateway.gw"]
  root_block_device {
    delete_on_termination = true
    volume_size = 8
  }
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 8
    delete_on_termination = true
  }
  tags = {
    Name = "web"
  }
}

resource "aws_instance" "db" {
  ami           = "ami-0bb35a5dad5658286"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_incoming_ssh.id}"]
  key_name = "${aws_key_pair.ansible.key_name}"
  depends_on = ["aws_internet_gateway.gw"]
  root_block_device {
    volume_size = 8
    delete_on_termination = true
  }
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 8
    delete_on_termination = true
  }
  tags = {
    Name = "db"
  }
}

resource "aws_instance" "jenkins" {
  ami           = "ami-0bb35a5dad5658286"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_incoming_ssh.id}"]
  key_name = "${aws_key_pair.ansible.key_name}"
  depends_on = ["aws_internet_gateway.gw"]
  root_block_device {
    volume_size = 8
    delete_on_termination = true
  }
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 8
    delete_on_termination = true
  }
  tags = {
    Name = "jenkins"
  }
}
