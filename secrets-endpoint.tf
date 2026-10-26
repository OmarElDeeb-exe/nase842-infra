# Security group for the Secrets Manager endpoint
resource "aws_security_group" "secrets_endpoint" {
  name        = "nase842-secrets-endpoint-sg"
  description = "Private access to AWS Secrets Manager"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "nase842-secrets-endpoint-sg"
    Project = "NASE-842"
  }
}

# Endpoint accepts HTTPS only from Lambda
resource "aws_vpc_security_group_ingress_rule" "secrets_from_lambda" {
  security_group_id            = aws_security_group.secrets_endpoint.id
  referenced_security_group_id = aws_security_group.lambda.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS from Lambda"
}

# Lambda can access the Secrets Manager endpoint
resource "aws_vpc_security_group_egress_rule" "lambda_to_secrets" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.secrets_endpoint.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS to Secrets Manager endpoint"
}

# Private connectivity to AWS Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id
  ]

  security_group_ids = [
    aws_security_group.secrets_endpoint.id
  ]

  tags = {
    Name    = "nase842-secretsmanager-endpoint"
    Project = "NASE-842"
  }
}
