locals {
  storage_labels = {
    env     = var.env
    project = "knowledge-banking-graph"
  }
}

# Data lake: almacena CSVs/Parquet generados antes de cargarlos a BigQuery
resource "google_storage_bucket" "data_lake" {
  name          = "${var.project_id}-data-lake"
  location      = var.region
  project       = var.project_id
  force_destroy = true
  labels        = local.storage_labels

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

# Staging para jobs de Dataflow (archivos temporales del pipeline de Beam)
resource "google_storage_bucket" "dataflow_staging" {
  name          = "${var.project_id}-dataflow-staging"
  location      = var.region
  project       = var.project_id
  force_destroy = true
  labels        = local.storage_labels

  uniform_bucket_level_access = true
}
