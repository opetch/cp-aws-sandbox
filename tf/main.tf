provider "aws" {
  region = "eu-west-2"
}

locals {
  region = "eu-west-2"
  name = "confluent"
  tmp_private_key_file = "${path.module}/private_key.pem"
  provisoner_ip_cidr = "${chomp(data.http.provisoner_ip.body)}/32"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = local.name

  cidr = "10.0.0.0/16"

  azs            = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  vpc_tags = {
    Name = "${local.name}-vpc"
  }
}

data "aws_ami" "centos" {
  most_recent = true
  owners      = ["125523088429"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["CentOS 7.*"]
  }
}

resource "aws_instance" "hosts" {
  count                       = var.instance_count
  ami                         = data.aws_ami.centos.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[count.index % 3]
  vpc_security_group_ids      = [aws_security_group.confluent.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.confluent.key_name

  tags = {
    Name = "${local.name}-${count.index}"
  }
}

data "http" "provisoner_ip" {
  url = "http://icanhazip.com"
}

resource "aws_security_group" "confluent" {
  name   = "${local.name}-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.provisoner_ip_cidr]
    description = "Allow Ansible to connect to hosts via SSH"
  }

  ingress {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = [local.provisoner_ip_cidr]
    description = "Confluet REST API"
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [local.provisoner_ip_cidr]
    description = "Kafka"
  }

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [local.provisoner_ip_cidr]
    description = "Zookeeper"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    # TODO create rules for individual ports
    description = "Allow instance in cluster to connect to one another on any port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg"
  }
}

resource "tls_private_key" "confluent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "confluent" {
  key_name   = local.name
  public_key = tls_private_key.confluent.public_key_openssh

  tags = {
    Name = "${local.name}-kp"
  }
}

resource "local_file" "private_key" {
  content  = tls_private_key.confluent.private_key_pem
  filename = local.tmp_private_key_file
  file_permission = "600"
}
