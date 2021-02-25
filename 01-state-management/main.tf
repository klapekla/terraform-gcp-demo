terraform {
  required_version = "~> 0.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/google"
      version = "~> 3.58.0"
    }
  }
}

provider "google" {
  region = var.region
}

resource "random_integer" "project" {
  min = 100000
  max = 999999
}

resource "random_integer" "bucket" {
  min = 100000
  max = 999999
}

resource "google_project" "terraform_state" {
  name            = var.project
  project_id      = "${var.project}-${random_integer.project.id}"
  billing_account = var.billing_account
}

resource "google_storage_bucket" "for_tf_state" {
  name          = "terraform-state-${random_integer.bucket.id}"
  project       = google_project.terraform_state.project_id
  location      = var.region
  force_destroy = true
  versioning {
    enabled = true
  }
}