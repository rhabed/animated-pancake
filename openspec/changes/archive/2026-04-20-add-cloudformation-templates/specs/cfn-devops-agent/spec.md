## ADDED Requirements

### Requirement: CloudFormation Template for DevOps Agent
The system SHALL provide a CloudFormation template in `aws-devops-agent/cfn/template.yaml` that provisions the same resources as the Terraform module, including IAM roles, policies, and the `AWS::DevOpsAgent::AgentSpace`.

#### Scenario: Provisioning DevOps Agent Space
- **WHEN** the template is deployed with valid parameters
- **THEN** an `AWS::DevOpsAgent::AgentSpace` resource is created with the specified name and description.

### Requirement: Management Scripts for DevOps Agent
The system SHALL provide `deploy.sh`, `update.sh`, and `delete.sh` scripts in `aws-devops-agent/cfn/` to manage the stack lifecycle.

#### Scenario: Successful stack deployment
- **WHEN** `deploy.sh` is executed with a valid `parameters.json` file
- **THEN** the CloudFormation stack is created successfully.

### Requirement: External Parameters File
The system SHALL support configuration via a `parameters.json` file following the AWS CLI CloudFormation parameters format.

#### Scenario: Parameter injection
- **WHEN** a parameter is changed in `parameters.json` and `update.sh` is run
- **THEN** the stack is updated with the new parameter value.

### Requirement: Unified Entry Point via Makefile
The system SHALL provide a `Makefile` at the root that allows deploying/updating/deleting the DevOps agent stack.

#### Scenario: Running make deploy
- **WHEN** `make deploy-devops-agent` is executed
- **THEN** it triggers the `aws-devops-agent/cfn/deploy.sh` script.
