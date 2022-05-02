terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "ap-southeast-1"
  profile = "rx9"
}

resource "aws_security_group" "sg_ssh_access" {
  name = "sg_ssh_access"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_public_http" {
  name = "sg_public_http"

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

resource "aws_key_pair" "rx9" {
  key_name   = "rx9_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIv/elDFeDBnAhgz+arIi7Sd/ZTsP3Hdeo/rbdpi7+x3isPlQr57QPiBcpo4GWAP2eFalceU3H5Rde46GGMxcb2woppzuM73DkD0jQzv0bKmAHWI5MPGiT6gzbAlUw6BPYrkKmIpuymMHnI8Q5KwvUj2ooFWFksp6KjbnRxjQ8J2W2bmmE2AHv3PyXtDz+gBMKXhHGrVOC8Ti3fggYhUJ4X3BcezdoHqKt3jTsmWRoRjxXGmwLvGrm3sk7YN3McEr58z+QHJR2CUceQC6wquPsaoJq0b5DN2q64LZP1q7HAeXi2BczL54583+vF2Cf036kw+2IxXxSXvtE0c/OZi1xRL/U95Oh5d4tj4vluvDDNp/rxxMHowJ/9A/yn3ic9QHWUasmRIjebDbLRodjttjD7xZyPTmoalhUfPgcMLMoKmJzRedPj/AGetkJXgN3BbzD4WGHqN63J+lkqdXAzBITJxOufFnOSBpjGmKsF/eMLWzZ4phb4a2I5whQv+i8iCM= phu.nguyen@LAP00231.local"
}


resource "aws_instance" "wordpress" {
  ami             = "ami-04d9e855d716f9c99"
  instance_type   = "t3.micro"
  key_name        = aws_key_pair.rx9.key_name
  security_groups = [aws_security_group.sg_ssh_access.name, aws_security_group.sg_public_http.name]
  user_data       = file("init-wordpress.sh")

  tags = {
    Name = "Wordpress"
  }
}

resource "aws_instance" "random_logger" {
  ami             = "ami-04d9e855d716f9c99"
  instance_type   = "t3.micro"
  key_name        = aws_key_pair.rx9.key_name
  security_groups = [aws_security_group.sg_ssh_access.name, aws_security_group.sg_public_http.name]
  user_data       = file("init-random-logger.sh")

  tags = {
    Name = "RandomLogger"
  }
}
