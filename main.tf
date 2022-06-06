terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = "rx9"
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {
}

resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_key_pair" "rx9" {
  key_name   = "rx9_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIv/elDFeDBnAhgz+arIi7Sd/ZTsP3Hdeo/rbdpi7+x3isPlQr57QPiBcpo4GWAP2eFalceU3H5Rde46GGMxcb2woppzuM73DkD0jQzv0bKmAHWI5MPGiT6gzbAlUw6BPYrkKmIpuymMHnI8Q5KwvUj2ooFWFksp6KjbnRxjQ8J2W2bmmE2AHv3PyXtDz+gBMKXhHGrVOC8Ti3fggYhUJ4X3BcezdoHqKt3jTsmWRoRjxXGmwLvGrm3sk7YN3McEr58z+QHJR2CUceQC6wquPsaoJq0b5DN2q64LZP1q7HAeXi2BczL54583+vF2Cf036kw+2IxXxSXvtE0c/OZi1xRL/U95Oh5d4tj4vluvDDNp/rxxMHowJ/9A/yn3ic9QHWUasmRIjebDbLRodjttjD7xZyPTmoalhUfPgcMLMoKmJzRedPj/AGetkJXgN3BbzD4WGHqN63J+lkqdXAzBITJxOufFnOSBpjGmKsF/eMLWzZ4phb4a2I5whQv+i8iCM= phu.nguyen@LAP00231.local"
}

##############################
# Wordpress
##############################

data "template_file" "wordpress_user_data" {
  template = file("userdata-wordpress.sh.tpl")
  vars = {
    es_endpoint = aws_elasticsearch_domain.elasticsearch.endpoint
  }
}

resource "aws_security_group" "wordpress_sg" {
  name = "wordpress_sg"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "wordpress" {
  ami             = "ami-04d9e855d716f9c99"
  instance_type   = "t3.micro"
  key_name        = aws_key_pair.rx9.key_name
  security_groups = [aws_security_group.wordpress_sg.name]
  user_data       = data.template_file.wordpress_user_data.rendered

  tags = {
    Name = "Wordpress"
  }
}

##############################
# Microservices
##############################

data "template_file" "microservices_user_data" {
  template = file("userdata-microservices.sh.tpl")
  vars = {
    es_endpoint = aws_elasticsearch_domain.elasticsearch.endpoint
  }
}

resource "aws_security_group" "microservices_sg" {
  name = "microservices_sg"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "microservices" {
  ami             = "ami-04d9e855d716f9c99"
  instance_type   = "t3.micro"
  key_name        = aws_key_pair.rx9.key_name
  security_groups = [aws_security_group.microservices_sg.name]
  user_data       = data.template_file.microservices_user_data.rendered

  tags = {
    Name = "Microservices"
  }
}

##############################
# Opensearch Service
##############################

variable "es_domain_name" {
  default = "elasticsearch"
}

variable "es_subnet_id" {
  default = "subnet-ffd10799"
}

resource "aws_security_group" "es_sg" {
  name = "es_sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticsearch_domain" "elasticsearch" {
  domain_name           = var.es_domain_name
  elasticsearch_version = "7.10"

  vpc_options {
    security_group_ids = [aws_security_group.es_sg.id]
    subnet_ids         = [var.es_subnet_id]
  }

  cluster_config {
    instance_type = "t3.small.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.es_domain_name}/*"
        }
    ]
}
CONFIG

  tags = {
    Domain = "ElasticSearch"
  }
}


###############################
# VPN
###############################

variable "openvpn_ami" {
  description = "OpenVPN access server with 10 connected devices in region ap-southeast-1"
  default     = "ami-0ec7ca9f721da8e69"
}

variable "openvpn_subnet_id" {
  description = "This should be different with the subnet for opensearch service"
  default     = "subnet-3361a67b"
}

resource "aws_security_group" "vpn_server_sg" {
  name        = "vpn_server_sg"
  description = "Security group for VPN access server"
  vpc_id      = aws_default_vpc.default_vpc.id

  tags = {
    Name = "vpn_server_sg"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 943
    to_port     = 943
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "vpn_server" {
  ami                    = var.openvpn_ami
  instance_type          = "t3.nano"
  vpc_security_group_ids = ["${aws_security_group.vpn_server_sg.id}"]
  subnet_id              = var.openvpn_subnet_id
  key_name               = aws_key_pair.rx9.key_name

  tags = {
    Name = "VPN Server"
  }
}

output "wordpress_url" {
  value = "http://${aws_instance.wordpress.public_ip}"
}

output "es_endpoint" {
  description = "Domain-specific endpoint used to submit index, search, and data upload requests."
  value       = aws_elasticsearch_domain.elasticsearch.endpoint
}

output "vpn_server_dns" {
  value = aws_instance.vpn_server.public_ip
}
