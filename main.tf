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
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.pj-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-2a"

  tags = {
    Name = "Public-subnet-1"
  }
}

# Create EC2 instances
resource "aws_instance" "my-instance" {
  ami           = "ami-08a6efd148b1f7504"
  instance_type = "t2.large"
  key_name      = "PJ-3-key"
  count         = 2
  subnet_id     = aws_subnet.public-subnet-1.id
  associate_public_ip_address = true

  tags = {
    Name = "pj-instance-${count.index + 1}"
  }
}

# Output list of public IPs
output "public_ip_of_servers" {
  value = aws_instance.my-instance[*].public_ip
}
