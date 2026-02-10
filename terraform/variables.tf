variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west2"
}

variable "github_owner" {
  description = "GitHub username/org"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name"
  type        = string
  default     = "cicd-test"
}