# Acceptance Criteria and Validation

This document describes how to verify the acceptance criteria for the AWS DevOps Agent Terraform module.

## Prerequisites for validation

- Terraform >= 1.0
- AWS CLI configured with credentials that can create IAM roles and DevOps Agent resources
- AWS region: **us-east-1** only (enforced by variable validation)

## Acceptance criteria checklist

### 1. All 13 subtasks completed and merged

| ID   | Summary | Status |
|------|---------|--------|
| T-01 | Repository scaffold | ✅ |
| T-02 | variables.tf (incl. resource_discovery_tags) | ✅ |
| T-03 | iam.tf — DevOpsAgentRole-AgentSpace | ✅ |
| T-04 | iam.tf — DevOpsAgentRole-WebappAdmin (conditional) | ✅ |
| T-05 | main.tf — Agent Space and primary account association | ✅ |
| T-06 | main.tf — Cross-account associations | ✅ |
| T-07 | outputs.tf — All output values | ✅ |
| T-08 | deploy.sh and post-deploy.sh | ✅ |
| T-09 | setup-cross-account-roles.sh | ✅ |
| T-10 | cleanup.sh | ✅ |
| T-11 | terraform.tfvars.example | ✅ |
| T-12 | README.md — Full module documentation | ✅ |
| T-13 | End-to-end testing and acceptance validation | ✅ (this doc) |

### 2. `terraform apply` completes without errors in a clean AWS account

1. Use the `examples/single-account` example.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust if needed.
3. Run `./scripts/deploy.sh` or:
   ```bash
   terraform init
   terraform validate
   terraform plan -out=tfplan
   terraform apply tfplan
   ```
4. Confirm no errors; outputs show `agent_space_id`, `agent_space_arn`, role ARNs, and `manual_setup_instructions`.

### 3. `terraform destroy` cleanly removes all resources with no orphaned state

1. After a successful apply, run `./scripts/cleanup.sh` or `terraform destroy -auto-approve`.
2. Confirm all resources are destroyed (Agent Space, associations, IAM roles).
3. Verify in the AWS console (DevOps Agent, IAM) that no resources remain; no orphaned state in Terraform.

### 4. Module is idempotent — second `apply` produces no changes

1. After first `terraform apply`, run `terraform plan` again.
2. Expected: **No changes.** Your infrastructure matches the configuration.

### 5. `resource_discovery_tags` correctly scopes discovery

- **When set** (e.g. `resource_discovery_tags = { Environment = "prod" }`): Only resources with matching tags are discovered for topology.
- **When omitted or null**: All resources in the associated account(s) are discoverable.
- Validate in the AWS DevOps Agent console (topology / resource discovery) after apply.

### 6. README contains a working usage example

See [README.md](../README.md) — **Quick start** sections in `examples/`.

### 7. All acceptance for subtasks verified and documented

- IAM: `module/iam.tf` defines `DevOpsAgentRole-AgentSpace` and conditional `DevOpsAgentRole-WebappAdmin` with correct trust policies and managed policy attachments.
- Agent Space: `module/agentspace.tf` creates the Agent Space with optional Operator App (IAM/IDC).
- Associations: `module/associations.tf` handles primary and cross-account with optional `resource_discovery_tags`.
- Webhook: `module/webhook.tf` handles optional Event Channel association.
- Scripts: kept under `examples/**/scripts/`.

## Quick validation (no AWS credentials)

```bash
terraform init -backend=false
terraform validate
```

Both commands should succeed. A full `terraform plan` or `apply` requires valid AWS credentials in us-east-1.

