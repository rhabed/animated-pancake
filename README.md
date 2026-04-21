# AWS Agent Suite — IaC Modules

A comprehensive suite of Infrastructure as Code (IaC) modules and templates for automated, production-grade provisioning of **AWS DevOps Agent** and **AWS Security Agent**.

This repository provides both **Terraform modules** and **CloudFormation templates**, enabling you to version-control, review, and reproduce your agent configurations across accounts and environments with ease.

---

## Agent Overview

| Agent | Core Focus | Primary Capabilities |
|-------|------------|-----------------------|
| **AWS DevOps Agent** | Monitoring & Reliability | Automated resource discovery, anomaly detection, incident investigation, Operator App (interactive UI), cross-account topology. |
| **AWS Security Agent** | Security & Compliance | Code review scanning (controls & general purpose), automated vulnerability remediation (PR extraction), GitHub integration. |

---

## Deployment Options

This project supporting two primary Infrastructure as Code (IaC) paths:

1.  **Terraform**: Reusable modules found in the `terraform/` subdirectories of each agent.
2.  **CloudFormation**: Native templates (YAML) and management scripts found in the `cfn/` subdirectories.

---

## Getting Started

### 1. Unified Validation
Before deploying, you can validate the configurations for all agents and tools from the root directory:

```bash
# Validates all Terraform modules and CloudFormation templates
make validate
```

### 2. AWS DevOps Agent Quick Start

#### via Terraform
```bash
cd examples/single-account
cp terraform.tfvars.example terraform.tfvars
# Update variables as needed
./scripts/deploy.sh
```

#### via CloudFormation
```bash
cd aws-devops-agent/cfn
cp parameters.json.example parameters.json
# Populate parameters.json with your settings
./deploy.sh
```

### 3. AWS Security Agent Quick Start

#### via Terraform
```bash
# Use the security-agent example
cd examples/security-agent
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

#### via CloudFormation
```bash
cd aws-security-agent/cfn
cp parameters.json.example parameters.json
# Populate parameters.json (e.g. SubnetId, VpcId for scanning)
./deploy.sh
```

---

## Repository Structure

```text
.
├── aws-devops-agent/
│   ├── cfn/              # CloudFormation template + scripts
│   └── terraform/        # Terraform module + Lambda/scripts assets
├── aws-security-agent/
│   ├── cfn/              # CloudFormation template + scripts
│   └── terraform/        # Terraform module
├── examples/             # Runnable cross-agent samples
├── Makefile              # Unified validation entry point
└── README.md
```

---

## Module Reference (Terraform)

### AWS DevOps Agent
| Variable | Description | Default |
|----------|-------------|---------|
| `agent_space_name` | Name for the Agent Space | `MyAgentSpace` |
| `enable_operator_app` | Enable the Operator App web interface | `true` |
| `auth_flow` | Operator App auth: `iam` or `idc` | `iam` |
| `external_account_ids` | External account IDs for cross-account monitoring | `[]` |
| `enable_webhook` | Enable Event Channel integration | `false` |
| `enable_sns_lambda` | Create SNS topic and Lambda trigger | `false` |

### AWS Security Agent
| Variable | Description | Default |
|----------|-------------|---------|
| `agent_space_name` | Name for the Security Agent Space | (Required) |
| `enable_controls_scanning` | Enable compliance controls scanning | `null` |
| `enable_general_purpose_scanning`| Enable vulnerability scanning | `null` |
| `github_integration` | Type of GitHub integration (e.g. `github`) | `null` |
| `github_repositories` | List of `{owner, name, remediate_code}` | `[]` |
| `vpc_arn` | VPC for associated networking | `null` |

---

## License and References

- [AWS DevOps Agent User Guide](https://docs.aws.amazon.com/devopsagent/latest/userguide/)
- [AWS Security Agent User Guide](https://docs.aws.amazon.com/securityagent/latest/userguide/)
