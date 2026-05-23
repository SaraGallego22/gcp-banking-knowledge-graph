terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.25"
    }
  }

  # El bucket de estado se crea con scripts/bootstrap.sh antes de terraform init
  backend "gcs" {
    bucket = "evident-healer-459022-g0-tf-state"
    prefix = "banking-knowledge-graph/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
