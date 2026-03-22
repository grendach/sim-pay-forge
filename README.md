# sim-pay-forge

Payment provider POC on AWS — Terraform, single default VPC, HTTPS via ACM.

## Architecture

- **ALB** — public, HTTPS 443, 3 selected subnets from the default VPC
- **App** — single EC2 in ASG (nginx + Docker dependency gate), placed in private subnets when available, otherwise public fallback
- **DB** — single EC2 (MySQL), same private-preferred / public-fallback logic
- **SGs** — ALB ingress from `allowed_client_cidrs`, app ingress from ALB only, DB ingress from app only

> Current deployment: default VPC has no private subnets → app and DB run in public subnets (`workload_network_mode = public-fallback`). Add private subnets to the VPC and re-apply to move workloads there automatically.

## DNS

The hosted zone `grendach.dev` is managed in **Cloudflare**. After each deploy, copy `alb_dns_name` from `terraform output` and update the CNAME record in Cloudflare manually:

```
altm-dev.grendach.dev  CNAME  <alb_dns_name>
```

The ACM certificate for `altm-dev.grendach.dev` uses DNS validation — add the validation CNAME from `certificate_validation_records` output to Cloudflare once, then it auto-renews.

## Deploy

```bash
./aws-infra.sh apply
terraform output   # copy alb_dns_name → update Cloudflare CNAME
```

Restrict ingress in `environments/dev/terraform.tfvars` when needed:

```hcl
allowed_client_cidrs = [
  "185.72.187.163/32",
]
```

## Diagrams

```bash
# macOS prereqs (one-time)
brew install graphviz && python3 -m pip install diagrams
# generate → docs/poc-architecture-python.png
python3 docs/generate_infra_diagram.py
```

## Troubleshooting
❌ "No ACm cert": Create free cert in AWS Console (public domain or wildcard)
❌ "Invalid AMI": aws ec2 describe-images --owners amazon --region eu-central-1
❌ State locked: aws dynamodb get-item --table-name terraform-locks --key '{"LockID":{"S":"your-lock"}}'
❌ Permissions: Attach AdministratorAccess policy temporarily

## Cleanup
```
./aws-infra.sh destroy
```
