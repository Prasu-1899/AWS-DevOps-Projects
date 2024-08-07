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

resource "aws_instance" "app_server" {
  ami           = "ami-0bcedba63d7253ea7"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}



