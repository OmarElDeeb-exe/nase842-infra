# Allow CloudFront to securely access private S3
resource "aws_cloudfront_origin_access_control" "frontend" {
  name = "nase842-frontend-oac-eu"
  description                       = "OAC for NASE-842 Vue frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# HTTPS distribution for Vue
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "NASE-842 Vue frontend"
  default_root_object = "index.html"
  aliases = []
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "nase842-frontend-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "nase842-frontend-s3"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    compress        = true
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Support Vue Router deep links
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
  cloudfront_default_certificate = true
}

  tags = {
    Name    = "nase842-frontend"
    Project = "NASE-842"
  }
}

# Grant this CloudFront distribution read-only S3 access
data "aws_iam_policy_document" "frontend_cloudfront" {
  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_cloudfront.json
}

output "frontend_cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "frontend_cloudfront_id" {
  value = aws_cloudfront_distribution.frontend.id
}
