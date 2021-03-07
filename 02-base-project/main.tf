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
  name                = var.project
  project_id          = "${var.project}-${random_integer.project.id}"
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "compute" {
  project                    = google_project.this.project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
}

resource "google_compute_network" "this" {
  name                    = "my-vpc"
  project                 = google_project.this.project_id
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute, ]
}

resource "google_compute_subnetwork" "private" {
  name                     = "private-subnet"
  project                  = google_project.this.project_id
  ip_cidr_range            = "192.168.11.0/24"
  region                   = var.region
  network                  = google_compute_network.this.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  project       = google_project.this.project_id
  ip_cidr_range = "192.168.10.0/24"
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_compute_router" "nat" {
  name    = "my-router"
  project = google_project.this.project_id
  region  = var.region
  network = google_compute_network.this.name
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  project                            = google_project.this.project_id
  router                             = google_compute_router.nat.name
  region                             = google_compute_router.nat.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "internal_ingress" {
  name          = "allow-internal"
  project       = google_project.this.project_id
  network       = google_compute_network.this.id
  source_ranges = ["192.168.10.0/24", "192.168.11.0/24"]
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "iap_ingress" {
  name          = "allow-ingress-from-iap"
  project       = google_project.this.project_id
  network       = google_compute_network.this.id
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}