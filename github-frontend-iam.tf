# GitHub Actions trust policy: frontend/main only
data "aws_iam_policy_document" "github_frontend_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::253650698585:oidc-provider/token.actions.githubusercontent.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:OmarElDeeb-exe@348248498/nase842-frontend@1434256235:ref:refs/heads/main"
      ]
    }
  }
}

# Dedicated role for frontend deployment
resource "aws_iam_role" "github_frontend" {
  name               = "nase842-github-frontend-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_frontend_trust.json

  tags = {
    Project = "NASE-842"
  }
}

# Permissions limited to our S3 bucket and CloudFront distribution
resource "aws_iam_role_policy" "github_frontend" {
  name = "nase842-frontend-deploy-policy"
  role = aws_iam_role.github_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.frontend.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation"
        ]
        Resource = aws_cloudfront_distribution.frontend.arn
      }
    ]
  })
}

output "github_frontend_role_arn" {
  value = aws_iam_role.github_frontend.arn
}
