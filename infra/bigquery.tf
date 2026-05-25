# ──────────────────────────────────────────────────────────────────────────────
# BigQuery — arquitectura de 3 capas (medaillon pattern)
#
#   banking_raw       → datos sintéticos tal como se generan
#   banking_curated   → modelos dbt limpios y transformados
#   banking_embeddings → embeddings de Vertex AI para búsqueda vectorial
# ──────────────────────────────────────────────────────────────────────────────

locals {
  common_labels = {
    env     = var.env
    project = "knowledge-banking-graph"
  }
}

resource "google_bigquery_dataset" "raw" {
  dataset_id  = "banking_raw"
  description = "Datos sintéticos bancarios en bruto"
  location    = var.region
  project     = var.project_id
  labels      = local.common_labels
}

resource "google_bigquery_dataset" "curated" {
  dataset_id  = "banking_curated"
  description = "Datos curados por modelos dbt"
  location    = var.region
  project     = var.project_id
  labels      = local.common_labels
}

resource "google_bigquery_dataset" "embeddings" {
  dataset_id  = "banking_embeddings"
  description = "Embeddings de entidades para búsqueda vectorial"
  location    = var.region
  project     = var.project_id
  labels      = local.common_labels
}

# ── Tablas en banking_raw ──────────────────────────────────────────────────────

resource "google_bigquery_table" "customers" {
  dataset_id          = google_bigquery_dataset.raw.dataset_id
  table_id            = "customers"
  project             = var.project_id
  deletion_protection = false
  labels              = local.common_labels

  schema = jsonencode([
    { name = "customer_id", type = "STRING",    mode = "NULLABLE" },
    { name = "name",        type = "STRING",    mode = "NULLABLE" },
    { name = "email",       type = "STRING",    mode = "NULLABLE" },
    { name = "phone",       type = "STRING",    mode = "NULLABLE" },
    { name = "birth_date",  type = "DATE",      mode = "NULLABLE" },
    { name = "address",     type = "STRING",    mode = "NULLABLE" },
    { name = "city",        type = "STRING",    mode = "NULLABLE" },
    { name = "country",     type = "STRING",    mode = "NULLABLE" },
    { name = "segment",     type = "STRING",    mode = "NULLABLE" },
    { name = "created_at",  type = "TIMESTAMP", mode = "NULLABLE" },
  ])
}

resource "google_bigquery_table" "accounts" {
  dataset_id          = google_bigquery_dataset.raw.dataset_id
  table_id            = "accounts"
  project             = var.project_id
  deletion_protection = false
  labels              = local.common_labels

  schema = jsonencode([
    { name = "account_id",   type = "STRING",    mode = "NULLABLE" },
    { name = "customer_id",  type = "STRING",    mode = "NULLABLE" },
    { name = "account_type", type = "STRING",    mode = "NULLABLE" },
    { name = "balance",      type = "FLOAT",     mode = "NULLABLE" },
    { name = "currency",     type = "STRING",    mode = "NULLABLE" },
    { name = "status",       type = "STRING",    mode = "NULLABLE" },
    { name = "opened_at",    type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "branch_id",    type = "STRING",    mode = "NULLABLE" },
  ])
}

resource "google_bigquery_table" "transactions" {
  dataset_id          = google_bigquery_dataset.raw.dataset_id
  table_id            = "transactions"
  project             = var.project_id
  deletion_protection = false
  labels              = local.common_labels

  # Particionado por fecha para consultas eficientes (y más baratas)
  time_partitioning {
    type  = "DAY"
    field = "transaction_date"
  }

  schema = jsonencode([
    { name = "transaction_id",   type = "STRING",    mode = "NULLABLE" },
    { name = "account_id",       type = "STRING",    mode = "NULLABLE" },
    { name = "merchant_id",      type = "STRING",    mode = "NULLABLE" },
    { name = "amount",           type = "FLOAT",     mode = "NULLABLE" },
    { name = "currency",         type = "STRING",    mode = "NULLABLE" },
    { name = "transaction_type", type = "STRING",    mode = "NULLABLE" },
    { name = "category",         type = "STRING",    mode = "NULLABLE" },
    { name = "transaction_date", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "description",      type = "STRING",    mode = "NULLABLE" },
    { name = "status",           type = "STRING",    mode = "NULLABLE" },
  ])
}

resource "google_bigquery_table" "merchants" {
  dataset_id          = google_bigquery_dataset.raw.dataset_id
  table_id            = "merchants"
  project             = var.project_id
  deletion_protection = false
  labels              = local.common_labels

  schema = jsonencode([
    { name = "merchant_id", type = "STRING",  mode = "NULLABLE" },
    { name = "name",        type = "STRING",  mode = "NULLABLE" },
    { name = "category",    type = "STRING",  mode = "NULLABLE" },
    { name = "city",        type = "STRING",  mode = "NULLABLE" },
    { name = "country",     type = "STRING",  mode = "NULLABLE" },
    { name = "is_online",   type = "BOOLEAN", mode = "NULLABLE" },
  ])
}
