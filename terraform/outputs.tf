output "staging_url" {
  description = "URL of staging Cloud Run service"
  value       = google_cloud_run_service.staging.status[0].url
}

output "production_url" {
  description = "URL of production Cloud Run service"
  value       = google_cloud_run_service.production.status[0].url
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}