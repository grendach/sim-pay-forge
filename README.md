# sim-pay-forge

Secure Payment Provider POC on AWS using Terraform. The configuration prefers private subnets for app and DB workloads when they exist in the default VPC, but the current AWS account has no private subnets there, so app EC2 and DB EC2 are currently deployed in selected public subnets.

## Architecture
VPC: default VPC with 3 discovered public subnets for ALB

Current network mode: public fallback for workloads because no private subnets exist in the default VPC

ALB: HTTPS from allowed IPs only

ASG: single app EC2 instance in ASG with dependency-gated startup

EC2 MySQL: single DB EC2 with app-only access in selected default-VPC subnet

Security: Principle of least privilege SGs

Workload subnet behavior: if private subnets are later added to the default VPC, Terraform will place app and DB there; in the current setup it falls back to public subnets and reports `workload_network_mode = public-fallback`

Ingress allowlist behavior: ALB ingress is driven by `allowed_client_cidrs`, which accepts one or many CIDR blocks. The current dev example keeps `0.0.0.0/0` enabled for the POC, but you can switch to a finite list such as `185.72.187.163/32` or any office/VPN ranges.

Diagram: see docs/poc-architecture.md

Python diagram generator (PNG):

```bash
brew install graphviz
python3 -m pip install diagrams
python3 docs/generate_infra_diagram.py
```

Audit-focused diagram generator (PNG):

```bash
python3 docs/generate_audit_diagram.py
```

Audit contingency notes: see docs/audit-contingency.md

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

- Example ALB ingress allowlist override
```hcl
allowed_client_cidrs = [
  "0.0.0.0/0",
  "185.72.187.163/32",
]
```

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
# Copy alb_dns_name or alb_https_url
# Check alb_subnet_ids, workload_subnet_ids, and workload_network_mode
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

✅ Default VPC discovery

✅ 3 selected public subnets for ALB placement

✅ App and DB placement in private subnets when available, otherwise public-subnet fallback

✅ Current account uses public-subnet fallback because the default VPC has no private subnets

✅ ALB (HTTPS:443 → allowed IPs only)

✅ ASG (1x t3.micro, ALB health checks)

✅ EC2 MySQL (single instance)

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
