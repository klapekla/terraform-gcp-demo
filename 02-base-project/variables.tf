variable "project" {
  type        = string
  description = "Project where the state of terraform will be stored"
}

variable "region" {
  type        = string
  description = "Name of GCP Default Region"
}

variable "billing_account" {
  type        = string
  description = "Display Name of Billing Account"
}