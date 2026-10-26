# HTTPS certificate for frontend and backend
resource "aws_acm_certificate" "realworld" {
  domain_name = "realworld.eldeeb-o-skillup.vertexlab.net"

  subject_alternative_names = [
    "api.realworld.eldeeb-o-skillup.vertexlab.net"
  ]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = "NASE-842"
  }
}

# Automatically create ACM validation records
resource "aws_route53_record" "realworld_validation" {
  for_each = {
    for option in aws_acm_certificate.realworld.domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id = "Z00728403K1Y5QR33Z7GF"

  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Verify domain ownership and certificate issuance
resource "aws_acm_certificate_validation" "realworld" {
  certificate_arn = aws_acm_certificate.realworld.arn

  validation_record_fqdns = [
    for record in aws_route53_record.realworld_validation :
    record.fqdn
  ]
}

output "realworld_certificate_arn" {
  value = aws_acm_certificate.realworld.arn
}
