# Route frontend domain to CloudFront
resource "aws_route53_record" "frontend" {
  for_each = toset(["A", "AAAA"])

  zone_id = "Z00728403K1Y5QR33Z7GF"
  name    = "realworld.eldeeb-o-skillup.vertexlab.net"
  type    = each.value

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
