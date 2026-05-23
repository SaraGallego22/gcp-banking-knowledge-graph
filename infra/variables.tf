variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region para todos los recursos"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "Repositorio GitHub en formato owner/repo (para Workload Identity Federation)"
  type        = string
}

variable "env" {
  description = "Entorno de despliegue (dev | prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "El entorno debe ser 'dev' o 'prod'."
  }
}
