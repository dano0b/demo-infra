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
  map_public_ip_on_launch = true
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

resource "aws_security_group" "allow_outgoing_any" {
  name        = "allow_outgoing_any"
  description = "Allow any outgoing traffic"
  vpc_id      = "${aws_vpc.main.id}"
}

resource "aws_security_group_rule" "egress-any" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.allow_outgoing_any.id}"
}

resource "aws_security_group" "allow_incoming_http" {
  name        = "allow-incoming-http"
  description = "Allow inbound HTTP traffic"
  vpc_id      = "${aws_vpc.main.id}"
}
resource "aws_security_group_rule" "ingress-http-3000" {
  type        = "ingress"
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.allow_incoming_http.id}"
}
resource "aws_security_group_rule" "ingress-http-8080" {
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.allow_incoming_http.id}"
}
resource "aws_security_group_rule" "ingress-http-80" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.allow_incoming_http.id}"
}

resource "aws_security_group" "allow_incoming_mongodb" {
  name        = "allow-incoming-mongodb"
  description = "Allow inbound mongodb traffic"
  vpc_id      = "${aws_vpc.main.id}"
}
resource "aws_security_group_rule" "ingress-mongodb" {
  type        = "ingress"
  from_port   = 27017
  to_port     = 27017
  protocol    = "tcp"
  cidr_blocks = ["${aws_instance.web.private_ip}/32"]
  security_group_id = "${aws_security_group.allow_incoming_mongodb.id}"
  depends_on = ["aws_instance.web"]
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
  vpc_security_group_ids = ["${aws_security_group.allow_outgoing_any.id}","${aws_security_group.allow_incoming_ssh.id}","${aws_security_group.allow_incoming_http.id}"]
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
  vpc_security_group_ids = ["${aws_security_group.allow_outgoing_any.id}","${aws_security_group.allow_incoming_mongodb.id}","${aws_security_group.allow_incoming_ssh.id}"]
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
  vpc_security_group_ids = ["${aws_security_group.allow_outgoing_any.id}","${aws_security_group.allow_incoming_ssh.id}","${aws_security_group.allow_incoming_http.id}"]
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

resource "aws_elb" "demoapp" {
  name               = "demoapp"
  subnets = ["${aws_subnet.main.id}"]
  security_groups = ["${aws_security_group.allow_outgoing_any.id}","${aws_security_group.allow_incoming_http.id}"]
  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:3000/"
    interval            = 30
  }

  instances                   = ["${aws_instance.web.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}
