terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-southeast-2"
}

# vpc A
resource "aws_vpc" "vpc-a" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-A"
  }
}

# internet gateway
resource "aws_internet_gateway" "vpc-a-igw" {
  vpc_id = aws_vpc.vpc-a.id

  tags = {
    Name = "VPC-A-IGW"
  }
}

# subnet A
resource "aws_subnet" "subnet-a" {
  vpc_id     = aws_vpc.vpc-a.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "Subnet-A"
  }
}

# subnet B (private)
resource "aws_subnet" "subnet-b" {
  vpc_id            = aws_vpc.vpc-a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "Subnet-B"
  }
}

# route table a
resource "aws_route_table" "route-table-a" {
  vpc_id = aws_vpc.vpc-a.id

  tags = {
    Name = "Route-Table-A"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-a-igw.id
  }
}

# route table a association
resource "aws_route_table_association" "route-table-association-a" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.route-table-a.id
}

resource "aws_route" "route-a" {
  route_table_id            = aws_route_table.route-table-a.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.vpc-a-igw.id
}

# route table b (private subnet)
resource "aws_route_table" "route-table-b" {
  vpc_id = aws_vpc.vpc-a.id

  tags = {
    Name = "Route-Table-B"
  }
}

# Associate the private route table with Subnet B
resource "aws_route_table_association" "route-table-association-b" {
  subnet_id      = aws_subnet.subnet-b.id
  route_table_id = aws_route_table.route-table-b.id
}


# Security group
resource "aws_security_group" "web-server-sg" {
  name        = "web-server-sg"
  description = "Allow SSH, HTTP & HTTPS"
  vpc_id      = aws_vpc.vpc-a.id

  tags = {
    Name = "web-server-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg-http" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0"  # Allow HTTP from anywhere
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "sg-app" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0"  # Allow from anywhere for app.js
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}

resource "aws_vpc_security_group_ingress_rule" "sg-ssh" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0"  # Allow SSH from anywhere
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "sg-https" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow HTTPS from anywhere
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


# EC2 instance with Nginx and Node.js
resource "aws_instance" "web_server" {
  ami           = "ami-0e84539e536a327dc"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet-a.id
  associate_public_ip_address = true
  key_name      = "sample-key-pair-firman" # ensure this key pair available
  vpc_security_group_ids = [aws_security_group.web-server-sg.id]  # attach security group

  tags = {
    Name = "Test-Web-Server-Instance-Firmansyw30"
  }

  # User data for nginx & node js
  user_data = <<-EOF
  #!/bin/bash
  # Update and install necessary packages
  sudo apt-get update -y
  sudo apt-get install -y git nginx curl

  # Check, Start and enable nginx
  sudo systemctl status nginx  # To check if it's properly installed
  sudo systemctl start nginx
  sudo systemctl enable nginx

  # Clone repository (ensure internet access and valid repo)
  git clone https://github.com/firmansyw30/dicoding-a387-jarkom-labs.git
  cd dicoding-a387-jarkom-labs || exit 1  # Exit if directory not found

  # Install nvm and Node.js
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install 14.15.4
  nvm use 14.15.4

  # Install dependencies and start Node.js application
  npm install
  npm run start

  EOF
}

output "instance_ip" {
  value = aws_instance.web_server.public_ip
}
