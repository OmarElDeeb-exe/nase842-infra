# Dedicated JWT signing secret for Flask
resource "aws_secretsmanager_secret" "jwt" {
  name                    = "nase842-jwt-signing-key"
  description             = "JWT signing key for NASE-842 Flask backend"
  recovery_window_in_days = 7

  tags = {
    Project = "NASE-842"
  }
}

output "jwt_secret_arn" {
  value = aws_secretsmanager_secret.jwt.arn
}
