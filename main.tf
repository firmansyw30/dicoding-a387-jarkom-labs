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

resource "aws_route_table_association" "route-table-association-a" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.route-table-a.id
}

# Security group
resource "aws_security_group" "allow_ssh_http" {
  name        = "web-server-sg"
  description = "Allow SSH, HTTP & HTTPS"
  vpc_id      = aws_vpc.vpc-a.id

  tags = {
    Name = "web-server-sg"
  }

  #ssh port 22
  ingress { 
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  #http port 80
  ingress { 
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  #https port 443
  ingress { 
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance with Nginx and Node.js
resource "aws_instance" "web_server" {
  ami           = "ami-0e84539e536a327dc"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet-a.id
  associate_public_ip_address = true
  key_name      = "sample-key-pair-firman" # ensure this key pair available

  tags = {
    Name = "Test-Web-Server-Instance-Firmansyw30"
  }

  # User data for nginx & node js
  user_data = <<-EOF
    #!/bin/bash
    # Update and install necessary packages
    sudo yum update -y
    sudo yum install -y git nginx

    # Start and enable nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx

    # Clone repository
    git clone https://github.com/firmansyw30/dicoding-a387-jarkom-labs.git
    cd dicoding-a387-jarkom-labs

    # Install nvm and Node.js
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
    source ~/.nvm/nvm.sh
    nvm install v14.15.4

    # Install dependencies and start Node.js application
    npm install
    npm run start

    # Configure Nginx as reverse proxy
    sudo cat > /etc/nginx/conf.d/default.conf <<EOL
    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://localhost:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    EOL

    # Restart Nginx to apply the configuration
    sudo systemctl restart nginx
  EOF
}

output "instance_ip" {
  value = aws_instance.web_server.public_ip
}
