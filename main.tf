terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-2"
}

# Define variable for VPC CIDR
variable "cidr_block" {
  default = "10.0.0.0/16"
}

# Create VPC
resource "aws_vpc" "pj-vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "pj-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.pj-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-2a"

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.pj-vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.pj-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ssh_sg" {
  vpc_id = aws_vpc.pj-vpc.id
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


# Create EC2 instances
resource "aws_instance" "my-instance" {
  ami           = "ami-0bd4cda58efa33d23"
  instance_type = "t3.large"
  key_name      = "devops-test"
  count         = 2
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  tags = {
    Name = "pj-instance-${count.index + 1}"
  }

  # Root Volume Configuration
  root_block_device {
    volume_size = 30      
    volume_type = "gp3"   
    delete_on_termination = true
  }
}

# Output list of public IPs
output "public_ip_of_servers" {
  value = aws_instance.my-instance[*].public_ip
}
