# Private subnet group for PostgreSQL
resource "aws_db_subnet_group" "postgres" {
  name        = "nase842-db-subnet-group"
  description = "Private subnets for NASE-842 PostgreSQL"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name    = "nase842-db-subnet-group"
    Project = "NASE-842"
  }
}
