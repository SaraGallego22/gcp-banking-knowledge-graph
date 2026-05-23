# bootstrap.ps1 — Ejecutar UNA sola vez antes de cualquier comando de Terraform.
#
# ¿Qué hace este script?
#   1. Habilita las APIs de GCP que Terraform necesita para crear el resto
#   2. Crea el bucket de GCS donde Terraform guardará su "estado" (terraform.tfstate)
#   3. Activa el versionamiento del bucket (permite recuperar estados anteriores)
#
# ¿Por qué antes de Terraform?
#   Terraform necesita un lugar donde guardar qué recursos ya creó. Ese lugar
#   es un bucket de GCS — pero ese bucket no puede crearlo Terraform mismo
#   (¡huevo y gallina!). Por eso lo creamos manualmente una sola vez aquí.

$ErrorActionPreference = "Stop"

$PROJECT_ID = "evident-healer-459022-g0"
$REGION     = "us-central1"
$BUCKET     = "$PROJECT_ID-tf-state"

Write-Host ""
Write-Host "Bootstrap — Banking Knowledge Graph" -ForegroundColor Cyan
Write-Host "  Proyecto: $PROJECT_ID"
Write-Host "  Region:   $REGION"
Write-Host "  Bucket:   gs://$BUCKET"
Write-Host ""

# ── 1. Habilitar APIs mínimas ──────────────────────────────────────────────────
# Estas APIs permiten que Terraform pueda crear IAM, WIF y el resto de recursos.
# iamcredentials + sts son las que hacen funcionar Workload Identity Federation.
Write-Host "Paso 1/3 — Habilitando APIs de GCP..." -ForegroundColor Yellow

gcloud services enable `
    iam.googleapis.com `
    iamcredentials.googleapis.com `
    sts.googleapis.com `
    cloudresourcemanager.googleapis.com `
    storage.googleapis.com `
    --project=$PROJECT_ID

Write-Host "  APIs habilitadas." -ForegroundColor Green

# ── 2. Crear bucket de Terraform state ────────────────────────────────────────
# El bucket guarda el archivo terraform.tfstate: el inventario de todo lo que
# Terraform ya creó en GCP. Sin él, Terraform no sabe qué existe.
Write-Host ""
Write-Host "Paso 2/3 — Creando bucket de Terraform state..." -ForegroundColor Yellow

$bucketExists = gcloud storage buckets describe "gs://$BUCKET" --project=$PROJECT_ID 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  El bucket gs://$BUCKET ya existe, continuando..." -ForegroundColor DarkYellow
} else {
    gcloud storage buckets create "gs://$BUCKET" `
        --project=$PROJECT_ID `
        --location=$REGION `
        --uniform-bucket-level-access `
        --public-access-prevention
    Write-Host "  Bucket creado." -ForegroundColor Green
}

# ── 3. Activar versionamiento ──────────────────────────────────────────────────
# Con versionamiento, si un terraform apply sale mal, puedes recuperar el estado
# anterior del bucket. Es como un historial de backups del estado de Terraform.
Write-Host ""
Write-Host "Paso 3/3 — Activando versionamiento del bucket..." -ForegroundColor Yellow

gcloud storage buckets update "gs://$BUCKET" --versioning
Write-Host "  Versionamiento activado." -ForegroundColor Green

# ── Resumen final ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap completado exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Cyan
Write-Host "  1. Copia el archivo de variables de Terraform:"
Write-Host "     copy infra\terraform.tfvars.example infra\terraform.tfvars"
Write-Host ""
Write-Host "  2. Despliega la infraestructura:"
Write-Host "     cd infra"
Write-Host "     terraform init"
Write-Host "     terraform plan"
Write-Host "     terraform apply"
Write-Host ""
Write-Host "  3. Despues del apply, copia estos outputs a GitHub Secrets:"
Write-Host "     - WIF_PROVIDER   -> terraform output -raw wif_provider"
Write-Host "     - GCP_SA_EMAIL   -> terraform output -raw github_actions_sa_email"
Write-Host "     - GCP_PROJECT_ID -> $PROJECT_ID"
Write-Host ""
