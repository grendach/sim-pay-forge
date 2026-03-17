#!/bin/bash

set -e

ENV=$1

if [[ -z "$ENV" ]]; then
  echo "Usage: ./deploy.sh [dev|prod]"
  exit 1
fi

echo "🚀 Deploying environment: $ENV"

terraform init -backend-config=environments/$ENV/backend.hcl

terraform plan -var-file=environments/$ENV/terraform.tfvars

terraform apply -var-file=environments/$ENV/terraform.tfvars
