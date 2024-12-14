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
  region = "ap-southeast-3"
}

# VPC A
resource "aws_vpc" "vpc-a" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-A"
  }
}

# Internet gateway
resource "aws_internet_gateway" "vpc-a-igw" {
  vpc_id = aws_vpc.vpc-a.id

  tags = {
    Name = "VPC-A-IGW"
  }
}

# Subnet A
resource "aws_subnet" "subnet-a" {
  vpc_id     = aws_vpc.vpc-a.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-southeast-3a"

  tags = {
    Name = "Subnet-A"
  }
}

# Subnet B (private)
resource "aws_subnet" "subnet-b" {
  vpc_id            = aws_vpc.vpc-a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-3b"

  tags = {
    Name = "Subnet-B"
  }
}

# Route table A
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

# Route table A association
resource "aws_route_table_association" "route-table-association-a" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.route-table-a.id
}

resource "aws_route" "route-a" {
  route_table_id            = aws_route_table.route-table-a.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.vpc-a-igw.id
}

# Route table B (private subnet)
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
  cidr_ipv4         = "0.0.0.0/0"  # Allow ingress HTTP from anywhere
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "sg-ssh" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0"  # Allow SSH ingress from anywhere
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "sg-https" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow HTTPS ingress from anywhere
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_ingress_rule" "sg-express" {
  security_group_id = aws_security_group.web-server-sg.id
  cidr_ipv4         = "0.0.0.0/0" # Security Group to access the app.js
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}

# EC2 instance
resource "aws_instance" "web_server" {
  ami           = "ami-012972a9e728b3b9c"
  instance_type = "t3.nano"
  subnet_id     = aws_subnet.subnet-a.id
  associate_public_ip_address = true
  key_name      = "sample-key-pair-firman" # Ensure this key pair available (created on console)
  vpc_security_group_ids = [aws_security_group.web-server-sg.id]  # attach security group

  tags = {
    Name = "Test-Web-Server-Instance-Firmansyw30"
  }

  # User data for node js, fix it later
  user_data = file("startup.sh")
}

output "instance_ip" {
  value = aws_instance.web_server.public_ip
}
