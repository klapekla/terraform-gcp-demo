terraform {
  required_version = "~> 0.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/google"
      version = "~> 3.58.0"
    }
  }
  
  backend "gcs" {}
}

provider "google" {
  region = var.region
}

resource "random_integer" "project" {
  min = 100000
  max = 999999
}

resource "google_project" "this" {
  name            = var.project
  project_id      = "${var.project}-${random_integer.project.id}"
  billing_account = var.billing_account
}