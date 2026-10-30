
# NASE-842 - VPC for Ireland

resource "aws_vpc" "main" {
  cidr_block           = "10.85.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "nase842-vpc-eu"
    Project = "NASE-842"
  }
}

# Private Subnet A - Ireland AZ A

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.85.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = false

  tags = {
    Name    = "nase842-private-a-eu"
    Project = "NASE-842"
  }
}

# Private Subnet B - Ireland AZ B

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.85.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = false

  tags = {
    Name    = "nase842-private-b-eu"
    Project = "NASE-842"
  }
}
