# Use our AWS account ID for a unique bucket name
data "aws_caller_identity" "nase842" {}

# Private S3 bucket for the Vue frontend
resource "aws_s3_bucket" "frontend" {
  bucket        = "nase842-frontend-${data.aws_caller_identity.nase842.account_id}-us-east-1"
  force_destroy = false

  tags = {
    Name    = "nase842-frontend"
    Project = "NASE-842"
  }
}

# Block all public S3 access
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disable ACL-based ownership
resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Encrypt stored frontend files
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}
