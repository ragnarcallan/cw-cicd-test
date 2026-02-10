# Provider configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "cw-cicd-test"
  description   = "Docker repository for cicd-test app"
  format        = "DOCKER"
}

# Cloud Run service - Staging
resource "google_cloud_run_service" "staging" {
  name     = "cw-cicd-test-staging"
  location = var.region

  template {
    spec {
      containers {
        # Initial placeholder image (will be updated by Cloud Build)
        image = "${var.region}-docker.pkg.dev/${var.project_id}/cw-cicd-test/app:staging"

        ports {
          container_port = 8000
        }
        
        env {
          name  = "ENVIRONMENT"
          value = "staging"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  # Ignore image changes (Cloud Build will update)
  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
    ]
  }
}

# Cloud Run service - Production
resource "google_cloud_run_service" "production" {
  name     = "cw-cicd-test-production"
  location = var.region

  template {
    spec {
      containers {
        # Initial placeholder image
        image = "${var.region}-docker.pkg.dev/${var.project_id}/cw-cicd-test/app:production"

        ports {
          container_port = 8000
        }
        
        env {
          name  = "ENVIRONMENT"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
    ]
  }
}

# IAM - Allow public access to staging
resource "google_cloud_run_service_iam_member" "staging_public" {
  service  = google_cloud_run_service.staging.name
  location = google_cloud_run_service.staging.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM - Allow public access to production
resource "google_cloud_run_service_iam_member" "production_public" {
  service  = google_cloud_run_service.production.name
  location = google_cloud_run_service.production.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Service account for Cloud Build
resource "google_service_account" "cloudbuild" {
  account_id   = "cloudbuild-sa"
  display_name = "Cloud Build Service Account"
  description  = "Service account for Cloud Build deployments"
}

# IAM - Cloud Build can deploy to Cloud Run
resource "google_project_iam_member" "cloudbuild_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

# IAM - Cloud Build can act as service accounts
resource "google_project_iam_member" "cloudbuild_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

# IAM - Cloud Build can write to Artifact Registry
resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

# Cloud Build trigger - Staging (on master merge)
#resource "google_cloudbuild_trigger" "staging" {
#  name        = "deploy-staging"
#  description = "Deploy to staging on master merge"
#  location    = var.region#
#
#  github {
#    owner = var.github_owner
#    name  = var.github_repo
#    push {
#      branch = "^master$"
#    }
#  }
#
#  filename = "cloudbuild.yaml"
#
#  substitutions = {
#    _ENVIRONMENT = "staging"
#    _REGION      = var.region
#  }
#
#  service_account = google_service_account.cloudbuild.id
#}

# Cloud Build trigger - Production (on release/tag)
#resource "google_cloudbuild_trigger" "production" {
#  name        = "deploy-production"
#  description = "Deploy to production on release"
#  location    = var.region
#
#  github {
#    owner = var.github_owner
#    name  = var.github_repo
#    push {
#      tag = ".*"  # Any tag triggers production deploy
#    }
#  }
#
#  filename = "cloudbuild.yaml"
#
#  substitutions = {
#    _ENVIRONMENT = "production"
#    _REGION      = var.region
#  }
#
#  service_account = google_service_account.cloudbuild.id
#}