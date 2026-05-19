output "api_gateway_url" {
  description = "URL base del API Gateway"
  value       = module.lambda_api_ses.api_gateway_url
}

output "lambda_function_ses_name" {
  description = "Nombre de la función Lambda"
  value       = module.lambda_api_ses.lambda_function_name_ses
}