# MG Infrastructure as Code (IaC)

Infraestructura de Materia Gris en Terraform. Despliegue automatizado con GitHub Actions.

## 📁 Estructura

- `.github/workflows/` — Pipelines CI/CD
- `envs/` — Variables por entorno (`dev.tfvars`, `staging.tfvars`, `prod.tfvars`)
- `terraform.tfvars` — ⚠️ Solo local, ignorado en Git

---

## 🚀 Comandos

### Primera vez (crear bucket S3 del state)
```bash
./bootstrap-backend.sh <env>   # dev | staging | prod
```

### Init
```bash
terraform init -backend-config=envs/<env>/backend.hcl
```

### Plan / Apply
```bash
terraform plan  -var-file=envs/<env>.tfvars
terraform apply -var-file=envs/<env>.tfvars
```

### Destroy
```bash
terraform destroy -var-file=envs/<env>.tfvars
```