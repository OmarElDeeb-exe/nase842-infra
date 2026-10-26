# IAM role used by Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "nase842-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Allow Lambda to write CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to retrieve the Docker image from ECR
resource "aws_ecr_repository_policy" "lambda_access" {
  repository = aws_ecr_repository.flask.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "LambdaECRImageRetrievalPolicy"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ]
    }]
  })
}

# Flask backend running on Lambda
resource "aws_lambda_function" "flask" {
  environment {
    variables = {
      DB_SECRET_ARN  = aws_db_instance.postgres.master_user_secret[0].secret_arn
      POSTGRES_HOST  = aws_db_instance.postgres.address
      POSTGRES_DB    = aws_db_instance.postgres.db_name
      JWT_SECRET_ARN = aws_secretsmanager_secret.jwt.arn
    }
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_group_ids = [
      aws_security_group.lambda.id
    ]
  }

  function_name = "nase842-flask"
  role          = aws_iam_role.lambda_exec.arn

  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.flask.repository_url}:v5"
  architectures = ["x86_64"]

  memory_size = 512
  timeout     = 20

  lifecycle {
    ignore_changes = [image_uri]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_ecr_repository_policy.lambda_access
  ]

  tags = {
    Project = "NASE-842"
  }
}

output "lambda_function_name" {
  value = aws_lambda_function.flask.function_name
}
