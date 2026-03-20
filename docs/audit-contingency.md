# Audit Contingency Plan (5-Day Window)

## Goal
Pass external audit with compensating controls while full target-state hardening is still in progress.

## Immediate Controls (Day 0-1)
- Restrict ALB ingress to finite CIDR allowlist only (`allowed_client_cidrs`).
- Keep app and DB non-public when private subnets are available.
- Use security-group-only DB ingress from app SG on port 3306.
- Require startup dependency gate on app instance (docker-ce install + rpm verification).
- Keep all infrastructure changes in Terraform plan/apply workflow with remote state locking.

## Evidence Pack for Auditors (Day 1-2)
- Terraform plan output showing SG, ALB, ASG, DB and subnet mode.
- Terraform outputs: `alb_subnet_ids`, `workload_subnet_ids`, `workload_network_mode`.
- EC2 and SG screenshots/CLI outputs proving inbound allowlist and DB isolation.
- User-data logs proving dependency gate and secureweb HTTPS check.
- Diagram files: `docs/poc-architecture.md`, `docs/poc-architecture-python.png`, `docs/poc-architecture-audit.png`.

## Temporary Risk Acceptance (if needed)
- If default VPC has no private subnets, workloads run in `public-fallback` mode.
- In fallback mode, maintain strict CIDR ingress and document residual risk explicitly.
- Keep fallback period time-bound and approved by owner.

## Final Target State Rollout (Day 3-5+)
- Move workloads to dedicated private subnets with NAT or egress filtering.
- Replace fallback mode with enforced private-only workload placement.
- Enforce outbound allow policy for secureweb.com via egress proxy/AWS Network Firewall.
- Add CloudTrail/Config/GuardDuty evidence and baseline alerts.

## Discussion Points for Interview
- Why finite CIDR allowlist beats open 0.0.0.0/0 for audit posture.
- Why secureweb.com cannot be restricted by SG domain rule directly (needs proxy/firewall layer).
- Why a documented compensating-control plan is acceptable under strict delivery timelines.
