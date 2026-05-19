output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_function_name_ses" {
  value = aws_lambda_function.this.function_name
}