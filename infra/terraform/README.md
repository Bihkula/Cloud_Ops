# Cirrus — Infrastructure (Terraform)

Phase 2 of the project: everything in the target AWS architecture, codified. No
clicking in the console.

## What this builds

- **VPC** (`10.0.0.0/16`) with three subnet tiers across `az_count` AZs:
  - **public** — ALB + NAT Gateway (internet-facing)
  - **private** — Kubernetes (Kops) nodes / Cirrus pods (outbound only, via NAT)
  - **isolated** — RDS PostgreSQL (no internet route at all)
- **Internet Gateway**, **NAT Gateway**, per-tier route tables
- **S3 Gateway VPC Endpoint** (private S3 access for state + Kops)
- **S3 buckets** — Kops state store, artifacts (state bucket is in `bootstrap/`)
- **RDS PostgreSQL** in the isolated tier, encrypted, private-only
- **Secrets Manager** entry holding the full `DATABASE_URL` for Helm to inject
- **ECR** repository (scan-on-push, immutable tags, lifecycle policy)
- **IAM** policies for CI image push and node secret read
- Security groups enforcing `internet → ALB → app → RDS`

Every name and the app identity come from `variables.tf`. Changing `app_name`
is the entire v2 rebrand at this layer.

## Order of operations

```bash
# 0. One-time: create the remote-state bucket + lock table (uses LOCAL state)
cd bootstrap
terraform init && terraform apply
#   -> note the tfstate_bucket and tflock_table outputs

# 1. Wire those two values into ../backend.tf and uncomment the backend block
cd ..
terraform init -migrate-state

# 2. Security scan BEFORE apply (this is the IaC gate)
checkov -d . --config-file .checkov.yaml

# 3. Plan & apply
export TF_VAR_db_password='<a-strong-password-min-16-chars>'   # never commit this
terraform plan -out=plan.out
terraform apply plan.out

# 4. Read the handoff values for later phases
terraform output
```

## Handoff outputs (consumed by later phases)

| Output | Used by |
|---|---|
| `kops_state_store` | Phase 4 — `export KOPS_STATE_STORE=...` |
| `private_subnet_ids` / `public_subnet_ids` | Phase 4 — Kops cluster placement |
| `app_security_group_id` | Phase 4 — Kops node `additionalSecurityGroups` (lets RDS accept them) |
| `ecr_repository_url` | Phase 5/6 — docker push target, Helm `image.repository` |
| `rds_endpoint` / `database_url_secret_arn` | Phase 6 — Helm DB config / K8s Secret |
| `ci_ecr_push_policy_arn` | Phase 3/5 — attach to the CI runner identity |
| `cluster_name` | Phase 4 — Kops cluster name (`<app_name>.k8s.local`) |

## Security posture

`checkov` passes with **0 failures**. The handful of skipped checks are
deliberate cost/scope tradeoffs for a disposable learning environment and are
documented with reasons in `.checkov.yaml` (and inline where resource-specific).
Flip them on for a real production deployment: KMS CMKs, VPC flow logs, RDS
Performance Insights/enhanced monitoring, Multi-AZ, deletion protection.

## Cost & teardown

RDS, NAT, and (later) EC2/ELB bill hourly. Tear down when done:

```bash
terraform destroy
# bootstrap bucket has prevent_destroy; remove it manually only when truly done
```
