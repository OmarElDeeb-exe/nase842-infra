# Forward application API requests to Flask
resource "aws_apigatewayv2_route" "application" {
  api_id    = aws_apigatewayv2_api.flask.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.flask.id}"

  depends_on = [aws_lambda_permission.api_application]
}

# Allow our API Gateway to invoke Lambda for /api/* requests
resource "aws_lambda_permission" "api_application" {
  statement_id  = "AllowAPIGatewayAppInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flask.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.flask.execution_arn}/*/*/api/*"
}
