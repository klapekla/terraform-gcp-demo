# Terraform GCP Demo
creating infrastructure with terraform in google cloud

## Usage
```bash
tf_state_bucket=$(terraform output -raw bucket)
```

```bash
cd 02-base-project
terraform init \
    -backend-config="bucket=$tf_state_bucket" \
    -backend-config="prefix=terraform/state"
terraform plan
terraform apply
```