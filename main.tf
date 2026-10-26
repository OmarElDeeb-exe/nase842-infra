terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  ignore_tags {
    keys = [
      "AutoCreateDate",
      "AutoCreatedBy",
      "AutoRoleName"
    ]
  }
}

resource "aws_ecr_repository" "flask" {
  name                 = "nase842-flask"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "nase842-flask"
    Project = "NASE-842"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.flask.repository_url
}
