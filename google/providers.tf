terraform {
  required_version = "1.12.2"

  backend "gcs" {
    bucket = "weatherscanner-tf-state-gcp"
  }

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.44.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.3"
    }
  }
}

provider "google" {}