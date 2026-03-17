bucket         = "sim-pay-forge-terraform-state"
key            = "prod/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "terraform-locks"
encrypt        = true
