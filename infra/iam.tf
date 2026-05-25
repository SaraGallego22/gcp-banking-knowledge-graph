# ──────────────────────────────────────────────────────────────────────────────
# Workload Identity Federation (WIF)
#
# Permite que GitHub Actions se autentique en GCP sin guardar JSON keys.
# Flujo: GitHub OIDC token → GCP STS → credenciales temporales del SA.
# Docs: https://cloud.google.com/iam/docs/workload-identity-federation
# ──────────────────────────────────────────────────────────────────────────────

# Service Account que GitHub Actions va a impersonar
resource "google_service_account" "github_actions" {
  account_id   = "sa-github-actions"
  display_name = "GitHub Actions — Banking Knowledge Graph"
  project      = var.project_id

  depends_on = [google_project_service.apis]
}

# Pool de identidades externas (agrupa proveedores como GitHub, GitLab, etc.)
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  project                   = var.project_id

  depends_on = [google_project_service.apis]
}

# Proveedor dentro del pool: configura GitHub como emisor OIDC de confianza
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  project                            = var.project_id

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Mapea claims del token JWT de GitHub a atributos de GCP
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  # Solo acepta tokens del repositorio exacto — principio de mínimo privilegio
  attribute_condition = "assertion.repository == '${var.github_repo}'"
}

# Permite que identidades del repositorio impersonen el SA
resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# Roles necesarios para que el SA pueda desplegar recursos
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/bigquery.admin",
    "roles/storage.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user",
    "roles/secretmanager.secretAccessor",
    # Requerido para que terraform plan pueda leer el estado de google_project_service
    "roles/serviceusage.serviceUsageViewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}
