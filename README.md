# AWS DevOps Agent — Terraform Module

Production-grade Terraform module that automates the full lifecycle provisioning of **AWS DevOps Agent** resources. It replaces the manual AWS DevOps Agent CLI onboarding with Infrastructure as Code so you can version-control, review, and reproduce your DevOps Agent configuration across accounts and environments with a single `terraform apply`.

**Reference:** [AWS DevOps Agent — Getting Started with Terraform](https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-getting-started-with-aws-devops-agent-using-terraform.html)

## Scope

- **Agent Space** creation and management  
- **IAM roles and policies**: `DevOpsAgentRole-AgentSpace`, `DevOpsAgentRole-WebappAdmin` (conditional)  
- **Primary and cross-account** AWS account associations with optional **tag-based resource discovery** scoping  
- **Optional Operator App** deployment (IAM or IDC auth)  
- **Deployment and cleanup** automation scripts  
- Full module documentation  

## Prerequisites

- **Terraform** >= 1.0  
- **AWS CLI** configured with credentials that can create IAM roles/policies and DevOps Agent resources  
- **Region**: AWS DevOps Agent is only available in **us-east-1**  

## Quick start

### Single account

```bash
cd examples/single-account
cp terraform.tfvars.example terraform.tfvars
./scripts/deploy.sh
./scripts/post-deploy.sh
```

### Cross account

```bash
cd examples/cross-account
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
./scripts/setup-cross-account-roles.sh
```

**Manual deploy:**

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

## Input variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region (must be `us-east-1`) | `us-east-1` | Yes |
| `agent_space_name` | Name for the Agent Space | `MyAgentSpace` | No |
| `agent_space_description` | Description for the Agent Space | `AgentSpace for monitoring my application` | No |
| `enable_operator_app` | Enable the Operator App web interface | `true` | No |
| `auth_flow` | Operator App auth: `iam` or `idc` | `iam` | No |
| `external_account_ids` | List of external account IDs for cross-account monitoring | `[]` | No |
| `resource_discovery_tags` | Optional map of tag key-value pairs to scope resource discovery. When set, only resources with these tags are discovered; when omitted, all resources are discoverable. | `null` | No |
| `tags` | Tags for all resources | `{}` | No |

### Example: tag-based resource discovery

```hcl
# Only discover resources tagged with these key-value pairs
resource_discovery_tags = {
  Environment = "production"
  Application = "myapp"
}
```

Omit `resource_discovery_tags` or set to `null` to discover all resources in associated account(s).

## Outputs

| Output | Description |
|--------|-------------|
| `agent_space_id` | Agent Space identifier |
| `agent_space_arn` | Agent Space ARN |
| `devops_agentspace_role_arn` | ARN of `DevOpsAgentRole-AgentSpace` |
| `devops_operator_role_arn` | ARN of `DevOpsAgentRole-WebappAdmin` (null if Operator App disabled) |
| `primary_association_id` | Primary (source) account association ID |
| `external_association_ids` | Map of external account ID → association ID |
| `manual_setup_instructions` | Next steps and verification commands |

## Cross-account monitoring

1. Deploy the module in the **monitoring account**: `./deploy.sh` then `./post-deploy.sh`.  
2. Generate cross-account role setup commands:  
   `./setup-cross-account-roles.sh`  
3. In **each external account**, run the printed commands to create `DevOpsAgentCrossAccountRole` with the trust policy and `AIOpsAssistantPolicy`.  
4. Add external account IDs to `terraform.tfvars`:  
   `external_account_ids = ["123456789012"]`  
5. Re-apply: `terraform apply`.  

## Scripts (examples)

| Script | Purpose |
|--------|---------|
| `examples/single-account/scripts/deploy.sh` | Checks prerequisites and applies Terraform. |
| `examples/single-account/scripts/post-deploy.sh` | Verification commands + webhook lookup (if enabled). |
| `examples/single-account/scripts/cleanup.sh` | Destroys resources for the example. |
| `examples/cross-account/scripts/setup-cross-account-roles.sh` | Prints cross-account role creation commands. |

## Cleanup

To remove all resources:

Use the `cleanup.sh` in the example you deployed from, or run `terraform destroy` in that example directory.

Or manually: `terraform destroy`.

**Warning:** This deletes the Agent Space and all associations. Ensure you have no critical dependency on this configuration before destroying.

## Idempotency and acceptance criteria

- **Idempotent**: A second `terraform apply` after a successful apply should report **No changes**.  
- **Clean destroy**: `terraform destroy` removes all resources without leaving orphaned state.  
- **resource_discovery_tags**: When set, discovery is scoped to resources with those tags; when omitted, all resources are discoverable.  
- **README**: This file includes the working usage example above.  

## Repo layout

```
.
├── module/              # reusable Terraform module
├── examples/            # runnable deployments
├── docs/                # acceptance + notes
└── README.md
```

## License and references

- [AWS DevOps Agent User Guide](https://docs.aws.amazon.com/devopsagent/latest/userguide/)  
- [Getting Started with AWS DevOps Agent using Terraform](https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-getting-started-with-aws-devops-agent-using-terraform.html)  
