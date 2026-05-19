locals {
  name = "${var.project_name}-${var.environment}"
}

# ─── IAM ──────────────────────────────────────────────────────────────────────
# Rol que asume la Lambda para ejecutarse y usar otros servicios AWS

resource "aws_iam_role" "lambda_role" {
  name = "${local.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Permiso para escribir logs en CloudWatch (básico, siempre necesario)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permiso para enviar correos con SES
resource "aws_iam_role_policy" "lambda_ses" {
  name = "${local.name}-ses-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ses:SendEmail", "ses:SendRawEmail"]
      Resource = "*"
    }]
  })
}

# ─── LAMBDA ───────────────────────────────────────────────────────────────────
# El zip placeholder es necesario para que Terraform cree la función.
# Tu GitHub Action luego sube el código real con update-function-code.

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = "exports.handler = async () => ({ statusCode: 200 })"
    filename = "index.js"
  }
}

resource "aws_lambda_function" "this" {
  function_name = local.name
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  memory_size   = var.lambda_memory
  timeout       = var.lambda_timeout

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  # Variables de entorno disponibles en tu código Node.js
  environment {
    variables = {
      ENVIRONMENT    = var.environment
      SES_FROM_EMAIL = var.ses_from_email
      SES_TO_EMAIL   = var.ses_to_email
    }
  }

  # Ignora cambios de código porque los maneja GitHub Actions, no Terraform
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

# Grupo de logs en CloudWatch con retención razonable
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = var.environment == "prod" ? 30 : 7
}

# ─── API GATEWAY ──────────────────────────────────────────────────────────────
# HTTP API (v2) — más barato y simple que REST API para este caso

resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"

  # CORS para que el frontend pueda llamar al API
  cors_configuration {
    allow_origins = var.environment == "prod" ? ["https://materiagris.pe"] : ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

# Integración: conecta el API Gateway con la Lambda
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  payload_format_version = "2.0"
}

# Ruta: POST /contact (ajusta el path a lo que necesites)
resource "aws_apigatewayv2_route" "contact" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /contact"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Permiso para que API Gateway pueda invocar la Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}