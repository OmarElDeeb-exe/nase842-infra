# Public HTTP API
resource "aws_apigatewayv2_api" "flask" {
  name          = "nase842-http-api"
  protocol_type = "HTTP"
}

# Connect API Gateway to Lambda
resource "aws_apigatewayv2_integration" "flask" {
  api_id                 = aws_apigatewayv2_api.flask.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.flask.invoke_arn
  payload_format_version = "2.0"
}

# Only expose the health-check endpoint for now
resource "aws_apigatewayv2_route" "ping" {
  api_id    = aws_apigatewayv2_api.flask.id
  route_key = "GET /api/ping"
  target    = "integrations/${aws_apigatewayv2_integration.flask.id}"
}

# Automatically deploy API changes
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.flask.id
  name        = "$default"
  auto_deploy = true
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flask.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.flask.execution_arn}/*/GET/api/ping"
}

# Public API URL
output "api_gateway_url" {
  value = aws_apigatewayv2_api.flask.api_endpoint
}
