terraform {
  required_version = "~> 0.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.58.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance_template" "example_app" {
  name         = "example-app-it"
  machine_type = "f1-micro"
  disk {
    source_image = data.google_compute_image.ubuntu.self_link
  }
  network_interface {
    subnetwork = "private-subnet"
  }
  metadata_startup_script = <<EOF
    #! /bin/bash
    sudo apt-get update
    sudo apt-get install apache2 -y
    sudo service apache2 restart
    echo '<!doctype html><html><body><h1>Example App</h1></body></html>' | tee /var/www/html/index.html
    EOF
}

resource "google_compute_region_instance_group_manager" "example_app" {
  name = "example-app-igm"

  base_instance_name = "app"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.example_app.id
  }
}