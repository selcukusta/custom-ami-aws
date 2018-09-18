provider "aws" {
  region     = "${var.region}"
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_KEY}"
}

resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "${var.public_subnet_cidr}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table" "web_public_routetable" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "web_public_routetable" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.web_public_routetable.id}"
}

resource "aws_security_group" "web_access" {
  name = "vpc_web_access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_key_pair" "sample_keypair" {
  key_name   = "aws-sample-key-pair"
  public_key = "${file("/Users/selcuk.usta/.ssh/id_rsa.pub")}"
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  owners = ["${var.ami_owner_id}"]
}

resource "aws_instance" "my_docker_image" {
  ami                         = "${data.aws_ami.ami.image_id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.sample_keypair.key_name}"
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.web_access.id}"]
  associate_public_ip_address = true
  source_dest_check           = false

  provisioner "remote-exec" {
    inline = [
      "sudo docker container run -d --name ${var.container_name} -p ${var.host_port}:${var.container_port} ${var.image_name}",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("/Users/selcuk.usta/.ssh/id_rsa")}"
      agent       = false
    }
  }
}

output "ec2_instance_ip" {
  value = "${aws_instance.my_docker_image.0.public_ip}"
}
