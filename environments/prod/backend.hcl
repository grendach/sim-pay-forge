bucket         = "sim-pay-forge-terraform-state"
key            = "prod/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "terraform-locks"
encrypt        = true
