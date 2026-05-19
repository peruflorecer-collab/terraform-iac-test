variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente: dev, staging, prod"
  type        = string
}

variable "project_name" {
  description = "Infraestructura para mg-website-backend y mg-website-frontend"
  type        = string
  default     = "mg-website-infra-back-front"
}

variable "lambda_memory" {
  description = "Memoria del Lambda en MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout del Lambda en segundos"
  type        = number
  default     = 30
}

variable "ses_from_email" {
  description = "Email verificado en SES para enviar correos"
  type        = string
}

variable "ses_to_email" {
  description = "Email destino para recibir formularios"
  type        = string
}