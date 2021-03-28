# Terraform GCP Demo
creating infrastructure with terraform in google cloud

## Overview

What we will build:
![gcp-diagram](./assets/terraform-gcp-demo.svg)

## Prerequisites

- Terraform installed on machine
- GCP account

## Usage

I devided this project in 3 parts:
1. create resources for statemanagement
2. create resources for the base infrastructure
3. create resources for an example application

### 1. Initialize for Remote Management of terraform state and state lock
Folder: 01-state-management

This folder contains files to create following ressources:
- Google "Admin" Project for managing state
- Google Storage Bucket for storing the terraform state files and locks

Commands:
```bash
cd 01-state-management
terraform init
terraform plan
terraform apply
tf_state_bucket=$(terraform output -raw bucket)
```

### 2. Creating infrastructure in Google Cloud
Folder: 02-base-infrastructure

After initialization of the remote state management this folder contains files to create following resources:
- Google Project for this new project
- VPC
- 1 Subnet for Region
- NAT Gateway
- Bastion Host incl. Service Account
- Firewall Rules

Commands:
```bash
cd 02-base-project
terraform init \
    -backend-config="bucket=$tf_state_bucket" \
    -backend-config="prefix=state-base-project"
terraform plan
terraform apply
```

### 3. Create example app in Google Cloud
Folder: 03-example-app

This creates 2 vm instances in an instance group and a loadbalancer as an example. 

Commands:
```bash
cd 03-example-app
terraform init \
    -backend-config="bucket=$tf_state_bucket" \
    -backend-config="prefix=example-app-project"
terraform plan
terraform apply
```

## Possible future Improvements
- [ ] Replacing Bastion Host through Google Bastion Module