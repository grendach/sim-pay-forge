#!/bin/bash

set -euo pipefail

# -------------------------------
# Usage: ./deploy.sh <action>
# <action> = apply | destroy
# -------------------------------

ENV="dev"
ACTION=${1:-apply}  # default action is apply

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
