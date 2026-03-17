#!/bin/bash

set -euo pipefail

# -------------------------------
# Usage: ./deploy.sh <env> <action>
# <env>    = dev | prod
# <action> = apply | destroy
# -------------------------------

ENV=${1:-}
ACTION=${2:-apply}  # default action is apply

# Validate environment
if [[ -z "$ENV" ]]; then
  echo "❌ Usage: ./deploy.sh <env> [apply|destroy]"
  exit 1
fi

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "❌ Invalid environment: $ENV (must be dev or prod)"
  exit 1
fi

# Validate action
if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
  echo "❌ Invalid action: $ACTION (must be apply or destroy)"
  exit 1
fi

echo "🚀 $ACTION-ing environment: $ENV"

# Terraform init with backend
terraform init -backend-config="environments/${ENV}/backend.hcl"

# Plan & apply/destroy
if [[ "$ACTION" == "apply" ]]; then
  terraform plan -var-file="environments/${ENV}/terraform.tfvars"
  terraform apply -var-file="environments/${ENV}/terraform.tfvars"
else
  terraform plan -destroy -var-file="environments/${ENV}/terraform.tfvars"
  terraform destroy -var-file="environments/${ENV}/terraform.tfvars"
fi

echo "✅ $ACTION completed for environment: $ENV"
