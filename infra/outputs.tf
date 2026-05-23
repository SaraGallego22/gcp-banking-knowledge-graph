output "wif_provider" {
  description = "WIF provider resource name — pégalo en GitHub Secret WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_sa_email" {
  description = "Email del SA de GitHub Actions — pégalo en GitHub Secret GCP_SA_EMAIL"
  value       = google_service_account.github_actions.email
}

output "data_lake_bucket" {
  description = "Nombre del bucket Data Lake en GCS"
  value       = google_storage_bucket.data_lake.name
}

output "bigquery_datasets" {
  description = "IDs de los datasets de BigQuery creados"
  value = {
    raw        = google_bigquery_dataset.raw.dataset_id
    curated    = google_bigquery_dataset.curated.dataset_id
    embeddings = google_bigquery_dataset.embeddings.dataset_id
  }
}
