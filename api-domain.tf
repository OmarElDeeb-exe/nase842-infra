# Custom HTTPS domain for Flask API
resource "aws_apigatewayv2_domain_name" "realworld_api" {
  domain_name = "api.realworld.eldeeb-o-skillup.vertexlab.net"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.realworld.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
    ip_address_type = "dualstack"
  }

  tags = {
    Project = "NASE-842"
  }
}

# Map custom domain to existing HTTP API
resource "aws_apigatewayv2_api_mapping" "realworld_api" {
  api_id      = aws_apigatewayv2_api.flask.id
  domain_name = aws_apigatewayv2_domain_name.realworld_api.id
  stage       = aws_apigatewayv2_stage.default.id
}

# Route API domain to API Gateway
resource "aws_route53_record" "realworld_api" {
  for_each = toset(["A", "AAAA"])

  zone_id = "Z00728403K1Y5QR33Z7GF"
  name    = aws_apigatewayv2_domain_name.realworld_api.domain_name
  type    = each.value

  alias {
    name = aws_apigatewayv2_domain_name.realworld_api.domain_name_configuration[0].target_domain_name

    zone_id = aws_apigatewayv2_domain_name.realworld_api.domain_name_configuration[0].hosted_zone_id

    evaluate_target_health = false
  }
}

output "realworld_api_url" {
  value = "https://${aws_apigatewayv2_domain_name.realworld_api.domain_name}"
}
