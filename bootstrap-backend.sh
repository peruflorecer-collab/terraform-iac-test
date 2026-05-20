#!/bin/bash
# =============================================================================
# bootstrap-backend.sh
# Crea el bucket S3 para el Terraform backend remoto.
# Uso: ./bootstrap-backend.sh <env>
# Ejemplo: ./bootstrap-backend.sh dev
# =============================================================================

set -euo pipefail

# ── Validar argumento ─────────────────────────────────────────────────────────
ENV="${1:-}"
if [[ -z "$ENV" ]]; then
  echo "❌  Uso: $0 <env>   (dev | staging | prod)"
  exit 1
fi

if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo "❌  Entorno inválido: '$ENV'. Debe ser dev, staging o prod."
  exit 1
fi

# ── Configuración ─────────────────────────────────────────────────────────────
PROJECT_NAME="mg-infra-back-front"
REGION="us-east-1"
BUCKET="${PROJECT_NAME}-terraform-state-${ENV}"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Terraform Backend Bootstrap                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo "  Entorno : $ENV"
echo "  Bucket  : $BUCKET"
echo "  Región  : $REGION"
echo ""

# ── Crear bucket S3 ───────────────────────────────────────────────────────────
if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null; then
  echo "✅  Bucket '$BUCKET' ya existe, se omite creación."
else
  echo "🪣  Creando bucket S3..."

  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi

  # Versioning — obligatorio para state remoto
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

  # Cifrado por defecto
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'

  # Bloquear acceso público
  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo "✅  Bucket '$BUCKET' creado con versioning, cifrado y acceso privado."
fi

# ── Generar backend config parcial para este entorno ─────────────────────────
BACKEND_FILE="envs/${ENV}/backend.hcl"
mkdir -p "envs/${ENV}"

cat > "$BACKEND_FILE" <<HCL
# Auto-generado por bootstrap-backend.sh — NO editar manualmente
bucket  = "${BUCKET}"
key     = "website-backend/terraform.tfstate"
region  = "${REGION}"
encrypt = true
HCL

echo "📄  Archivo backend generado: $BACKEND_FILE"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅  Bootstrap completado para el entorno: $ENV"
echo ""
echo "  Próximos pasos:"
echo "  1. terraform init -backend-config=envs/${ENV}/backend.hcl"
echo "  2. terraform apply -var-file=envs/${ENV}.tfvars"
echo "════════════════════════════════════════════════════════"
echo ""