# Habilita todas las APIs de GCP que el proyecto necesita.
# disable_on_destroy = false evita que terraform destroy las deshabilite
# (otras apps del proyecto podrían depender de ellas).
resource "google_project_service" "apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",       # Requerido para WIF
    "sts.googleapis.com",                  # Security Token Service — requerido para WIF
    "cloudresourcemanager.googleapis.com",
    "dataflow.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
