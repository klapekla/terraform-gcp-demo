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

resource "google_service_account" "example_app" {
  account_id   = "example-app-sa"
  display_name = "Service Account for the example app."
}

resource "google_project_iam_member" "example_app_logging" {
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.example_app.email}"
}

resource "google_project_iam_member" "example_app_metrics" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.example_app.email}"
}

resource "google_compute_instance_template" "example_app" {
  name         = "example-app-it"
  machine_type = "f1-micro"
  disk {
    source_image = data.google_compute_image.ubuntu.self_link
  }
  network_interface {
    subnetwork = "my-subnet"
  }
  metadata_startup_script = <<EOF
    #! /bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh && \
    sudo bash add-monitoring-agent-repo.sh && \
    sudo apt-get update
    sudo apt-get install -y stackdriver-agent

    curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh && \
    sudo bash add-logging-agent-repo.sh && \
    sudo apt-get update
    sudo apt-get install -y google-fluentd
    sudo apt-get install -y google-fluentd-catch-all-config-structured
    sudo service google-fluentd restart

    sudo apt-get update
    sudo apt-get install apache2 -y
    sudo service apache2 restart
    echo '<!doctype html><html><body><h1>Example App</h1></body></html>' | tee /var/www/html/index.html
    EOF
  service_account {
    email  = google_service_account.example_app.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    port = "80"
  }
}

resource "google_compute_region_instance_group_manager" "example_app" {
  name = "example-app-igm"

  base_instance_name = "app"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.example_app.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }
}

# Loadbalancer
resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}

resource "google_compute_target_http_proxy" "default" {
  name        = "target-proxy"
  description = "a description"
  url_map     = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
  name            = "url-map-target-proxy"
  description     = "a description"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_backend_service" "default" {
  name        = "backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_http_health_check.default.id]

  backend {
    group = google_compute_region_instance_group_manager.example_app.instance_group
  }
}

resource "google_compute_http_health_check" "default" {
  name               = "check-backend"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}