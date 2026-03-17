# sim-pay-forge

Secure Payment Provider POC on AWS using Terraform. Audit-ready infrastructure with private app/DB, public ALB, NAT egress, locked-down SGs.

## Architecture
VPC: 2 public (ALB/NAT), 2 private subnets (app/DB)

ALB: HTTPS from allowed IPs only

ASG: EC2 app instances with health-gated startup

EC2 MySQL: Private, app-only access

Security: Principle of least privilege SGs

## Usage

- Ensure AWS CLI configured
```bash
aws configure list
aws sts get-caller-identity  # Verify account/region
```

- Create S3 state bucket + DynamoDB lock (one-time)
```bash
aws s3 mb s3://sim-pay-forge-terraform-state --region eu-central-1
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region eu-central-1
```
## DEV env
```bash
cd environments/dev
```

- Copy & customize config
```bash
cp ../terraform.tfvars.example terraform.tfvars
```
- Edit terraform.tfvars if needed

- Terraform workflow
```bash
# Initialize (downloads providers, modules)
terraform init

# Validate syntax
terraform validate

# Dry-run (review resources)
terraform plan -out=tfplan

# Deploy (type 'yes')
terraform apply "tfplan"

# View outputs
terraform output
# Copy alb_dns_name → https://sim-pay-forge-dev-xxx.elb.eu-central-1.amazonaws.com
```
- Verify deployment
```bash
# Check ALB DNS (from terraform output)
curl -k https://sim-pay-forge-dev-xxx.elb.eu-central-1.amazonaws.com
# → <h1>🛒 Payment Provider Active</h1>

# AWS Console
aws ec2 describe-instances --filters "Name=tag:Name,Values=sim-pay-forge-dev-app-asg*"
aws elbv2 describe-load-balancers --names sim-pay-forge-dev-alb
```

## Expected Resources Created

✅ VPC (10.0.0.0/16)

✅ 2 Public subnets (ALB + NAT)

✅ 2 Private subnets (App + DB)

✅ Internet Gateway + NAT Gateway

✅ ALB (HTTPS:443 → allowed IPs only)

✅ ASG (1x t3.micro, ALB health checks)

✅ EC2 MySQL (private subnet)

✅ Security Groups (least privilege)

## Troubleshooting
❌ "No ACm cert": Create free cert in AWS Console (public domain or wildcard)
❌ "Invalid AMI": aws ec2 describe-images --owners amazon --region eu-central-1
❌ State locked: aws dynamodb get-item --table-name terraform-locks --key '{"LockID":{"S":"your-lock"}}'
❌ Permissions: Attach AdministratorAccess policy temporarily

## Cleanup
```
terraform destroy
```
