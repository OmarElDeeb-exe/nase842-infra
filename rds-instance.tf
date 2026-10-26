resource "aws_db_instance" "postgres" {
  identifier = "nase842-postgres"

  # Database engine
  engine         = "postgres"
  engine_version = "15.19"
  instance_class = "db.t4g.micro"

  # Database configuration
  db_name  = "realworlddb"
  username = "dbadmin"
  port     = 5432

  # AWS generates and manages the password
  manage_master_user_password = true

  # Storage
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Private networking
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Single-AZ to reduce costs
  multi_az = false

  # Backups and maintenance
  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  # Demo environment only
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name    = "nase842-postgres"
    Project = "NASE-842"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_secret_arn" {
  value = aws_db_instance.postgres.master_user_secret[0].secret_arn
}
