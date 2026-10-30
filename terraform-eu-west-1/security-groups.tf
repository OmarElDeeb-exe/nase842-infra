# Security group for AWS Lambda
resource "aws_security_group" "lambda" {
  name        = "nase842-lambda-sg"
  description = "Security group for Flask Lambda"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "nase842-lambda-sg"
    Project = "NASE-842"
  }
}

# Security group for PostgreSQL RDS
resource "aws_security_group" "rds" {
  name        = "nase842-rds-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "nase842-rds-sg"
    Project = "NASE-842"
  }
}

# Lambda can connect to PostgreSQL on port 5432
resource "aws_vpc_security_group_egress_rule" "lambda_to_rds" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.rds.id

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  description = "Allow Lambda to reach PostgreSQL"
}

# PostgreSQL only accepts connections from Lambda
resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.lambda.id

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  description = "Allow PostgreSQL connections from Lambda"
}
