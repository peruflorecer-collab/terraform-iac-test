terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend en S3 para guardar el state remoto
  # Crea el bucket manualmente una vez antes de hacer terraform init
  backend "s3" {
    bucket = "mg-infra-back-front-terraform-state"
    key    = "website-backend/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "lambda_api_ses" {
  source = "./modules/lambda_api_ses"

  project_name   = var.project_name
  environment    = var.environment
  lambda_memory  = var.lambda_memory
  lambda_timeout = var.lambda_timeout
  ses_from_email = var.ses_from_email
  ses_to_email   = var.ses_to_email
}