# VPC for NASE-842
resource "aws_vpc" "main" {
  cidr_block           = "10.84.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "nase842-vpc"
    Project = "NASE-842"
  }
}

# Private subnet in Availability Zone A
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.84.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name    = "nase842-private-a"
    Project = "NASE-842"
  }
}

# Private subnet in Availability Zone B
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.84.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name    = "nase842-private-b"
    Project = "NASE-842"
  }
}
