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
  region = "us-east-2"
}


resource "aws_security_group" "cluster_instance" {
  name = var.security_group_name
}

# Automatically update state to handle the security group's identifier being changed
moved {
  from = aws_security_group.instance
  to   = aws_security_group.cluster_instance
}