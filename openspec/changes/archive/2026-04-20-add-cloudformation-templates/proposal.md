## Why

Some organizations do not use Terraform and prefer native AWS CloudFormation for Infrastructure as Code. Providing CloudFormation templates for the existing modules increases accessibility and simplifies integration for these users.

## What Changes

- Create CloudFormation templates for both `aws-devops-agent` and `aws-security-agent` modules.
- Implement shell scripts (`deploy.sh`, `update.sh`, `delete.sh`) to manage the CloudFormation stacks.
- Externalize stack configuration into a parameters file.
- Provide a root `Makefile` to encapsulate script execution (e.g., `make deploy-devops-agent`).

## Capabilities

### New Capabilities
- `cfn-devops-agent`: CloudFormation template and port of the DevOps Agent infrastructure.
- `cfn-security-agent`: CloudFormation template and port of the Security Agent infrastructure.

### Modified Capabilities
<!-- No requirement changes to existing capabilities. -->

## Impact

This change adds a new way to deploy the agents using CloudFormation. It does not affect existing Terraform modules. Users will have the option to choose between Terraform and CloudFormation.
