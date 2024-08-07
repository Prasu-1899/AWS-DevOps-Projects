terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
}

# Creating VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "RDP-VPC"
  }
}

#Creating Public Subnet
resource "aws_subnet" "Pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "RDP-Pub-sub"
  }
}

#creating Private Subnet
resource "aws_subnet" "Prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "RDP-Pri-sub"
  }
}

#creating Internet Gateway
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "RDP-VPC-IGW"
  }
}

#Creating Public Route Table
resource "aws_route_table" "Pub-RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "RDP-VPC-PUB-RT"
  }
}

#Creating Public Route Table Association
resource "aws_route_table_association" "pubrtasso" {
  subnet_id      = aws_subnet.Pubsub.id
  route_table_id = aws_route_table.Pub-RT.id
}

#Creating Elastic IP
resource "aws_eip" "myeip" {
  domain   = "vpc"
}

#Creating NAT Gateway
resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.Pubsub.id

  tags = {
    Name = "MY-VPC-NAT"
  }
}

#Creating Private Route Table
resource "aws_route_table" "Pri-RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tnat.id
  }

  tags = {
    Name = "RDP-VPC-PRI-RT"
  }
}

#Creating Private Route Table Association
resource "aws_route_table_association" "prirtasso" {
  subnet_id      = aws_subnet.Prisub.id
  route_table_id = aws_route_table.Pri-RT.id
}

#Creating Security Group
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "RDP-VPC-SG"
  }
}

# Inbound Rules
resource "aws_vpc_security_group_ingress_rule" "allow_all" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  ip_protocol       = "tcp"
  to_port           = 65535
}

#Outbound Rules
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_all.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Creating Instances 
resource "aws_instance" "Jumpbox" {
    ami                         = "ami-0bcedba63d7253ea7"
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.Pubsub.id
    vpc_security_group_ids      = [aws_security_group.allow_all.id]
    key_name                    =  "puttykpm"
    associate_public_ip_address =  true
}

resource "aws_instance" "instance2" {
    ami                         = "ami-0bcedba63d7253ea7"
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.Prisub.id
    vpc_security_group_ids      = [aws_security_group.allow_all.id]
    key_name                    =  "puttykpm"
}

