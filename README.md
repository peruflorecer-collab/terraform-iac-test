# Doc
# MG Infrastructure as Code (IaC)

Este repositorio contiene la arquitectura de infraestructura basada en **Terraform** y **Terragrunt** para los entornos de Materia Gris. El despliegue está automatizado mediante GitHub Actions.

## 📁 Estructura del Proyecto

* `.github/workflows/`: Contiene los pipelines de automatización (CI/CD).
* `envs/`: Archivos de variables específicos para cada entorno (`dev.tfvars`, `staging.tfvars`, `prod.tfvars`).
* `terraform.tfvars`: **(Local únicamente)** Archivo en la raíz para tus pruebas locales en tu AWS personal. Está ignorado en Git para evitar subir credenciales o datos de prueba.

---

## 🚀 Flujo de Trabajo (GitOps)

### 1. Desarrollo Local
Para hacer pruebas en tu máquina sin afectar a nadie:
1. Configura tus variables locales en el archivo `terraform.tfvars` de la raíz.
2. Inicializa y simula tus cambios localmente:
   ```bash
   terraform init
   terraform plan