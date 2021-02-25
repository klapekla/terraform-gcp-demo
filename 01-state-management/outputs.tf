output "project_id" {
  value = google_project.terraform_state.project_id
}

output "bucket" {
  value = google_storage_bucket.for_tf_state.name
}