#!/usr/bin/env bash
# bootstrap.sh — Ejecutar UNA sola vez antes de cualquier comando de Terraform.
#
# Crea el bucket de GCS para el estado de Terraform y habilita las APIs mínimas
# necesarias para que WIF funcione. El resto de la infra la gestiona Terraform.

set -euo pipefail

PROJECT_ID="evident-healer-459022-g0"
REGION="us-central1"
BUCKET="${PROJECT_ID}-tf-state"

echo "🚀 Bootstrap — Banking Knowledge Graph"
echo "   Project: ${PROJECT_ID}"
echo "   Region:  ${REGION}"
echo ""

# 1. Habilitar APIs mínimas para que Terraform pueda crear el resto
echo "Habilitando APIs de GCP..."
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  storage.googleapis.com \
  --project="${PROJECT_ID}"

# 2. Crear bucket para el estado de Terraform (idempotente)
if gcloud storage buckets describe "gs://${BUCKET}" --project="${PROJECT_ID}" &>/dev/null; then
  echo "Bucket gs://${BUCKET} ya existe, continuando..."
else
  echo "Creando bucket de Terraform state: gs://${BUCKET}"
  gcloud storage buckets create "gs://${BUCKET}" \
    --project="${PROJECT_ID}" \
    --location="${REGION}" \
    --uniform-bucket-level-access \
    --public-access-prevention
fi

# 3. Habilitar versionamiento (permite recuperar estados anteriores)
gcloud storage buckets update "gs://${BUCKET}" --versioning

echo ""
echo "✅ Bootstrap completado!"
echo ""
echo "Próximos pasos:"
echo "  1. cp infra/terraform.tfvars.example infra/terraform.tfvars"
echo "  2. Edita infra/terraform.tfvars con tu project_id"
echo "  3. cd infra && terraform init"
echo "  4. terraform plan"
echo "  5. terraform apply"
echo ""
echo "Después de 'terraform apply', copia los outputs a GitHub Secrets:"
echo "  - WIF_PROVIDER   → output 'wif_provider'"
echo "  - GCP_SA_EMAIL   → output 'github_actions_sa_email'"
echo "  - GCP_PROJECT_ID → ${PROJECT_ID}"
