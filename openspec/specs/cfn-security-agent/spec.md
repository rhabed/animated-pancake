# Specification: CloudFormation Template for Security Agent

## Requirements

### Requirement: CloudFormation Template for Security Agent
The system SHALL provide a CloudFormation template in `aws-security-agent/cfn/template.yaml` that provisions the same resources as the Terraform module, including IAM roles, policies, and the `AWS::SecurityAgent::AgentSpace`.

#### Scenario: Provisioning Security Agent Space
- **WHEN** the template is deployed with valid parameters
- **THEN** an `AWS::SecurityAgent::AgentSpace` resource is created with the specified name.

### Requirement: Management Scripts for Security Agent
The system SHALL provide `deploy.sh`, `update.sh`, and `delete.sh` scripts in `aws-security-agent/cfn/` to manage the stack lifecycle.

#### Scenario: Successful stack deletion
- **WHEN** `delete.sh` is executed
- **THEN** the CloudFormation stack and all its resources are removed.

### Requirement: Support for Security Settings
The template SHALL support configuring code review settings (controls scanning, general purpose scanning) and GitHub integrated resources.

#### Scenario: Enabling code scanning
- **WHEN** `EnableControlsScanning` is set to true in `parameters.json`
- **THEN** the created Agent Space has controls scanning enabled.

### Requirement: Unified Entry Point via Makefile
The system SHALL provide a `Makefile` at the root that allows deploying/updating/deleting the Security agent stack.

#### Scenario: Running make deploy
- **WHEN** `make deploy-security-agent` is executed
- **THEN** it triggers the `aws-security-agent/cfn/deploy.sh` script.
