# Trust only the backend repository's main branch
data "aws_iam_policy_document" "github_backend_trust" {
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
        "repo:OmarElDeeb-exe@348248498/nase842-backend@1434256311:ref:refs/heads/main"
      ]
    }
  }
}

# Dedicated backend deployment role
resource "aws_iam_role" "github_backend" {
  name               = "nase842-github-backend-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_backend_trust.json

  tags = {
    Project = "NASE-842"
  }
}

# Least-privilege ECR and Lambda permissions
resource "aws_iam_role_policy" "github_backend" {
  name = "nase842-backend-deploy-policy"
  role = aws_iam_role.github_backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ]
        Resource = aws_ecr_repository.flask.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = aws_lambda_function.flask.arn
      }
    ]
  })
}

output "github_backend_role_arn" {
  value = aws_iam_role.github_backend.arn
}
