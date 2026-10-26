# Allow Lambda to read only the JWT signing secret
resource "aws_iam_role_policy" "lambda_jwt_secret" {
  name = "nase842-lambda-read-jwt-secret"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_secretsmanager_secret.jwt.arn
    }]
  })
}
