## Context

The current infrastructure is managed using Terraform. To support organizations that prefer native AWS tools, we need to provide CloudFormation templates that achieve the same resource configuration as the Terraform modules.

## Goals / Non-Goals

**Goals:**
- Provide 100% feature parity with existing Terraform modules for `aws-devops-agent` and `aws-security-agent`.
- Simplify stack management with bash scripts.
- Support configuration via a standardized parameters file.

**Non-Goals:**
- Porting existing state from Terraform to CloudFormation (this is for new deployments).
- Supporting other IaC tools like Pulumi or CDK in this change.

## Decisions

### Template Structure
Each module will have a corresponding CloudFormation template in YAML format:
- `aws-devops-agent/cfn/template.yaml`
- `aws-security-agent/cfn/template.yaml`

### Scripting
We will provide three scripts for each module to manage the lifecycle of the stack:
- `deploy.sh`: Creates a new stack.
- `update.sh`: Updates an existing stack.
- `delete.sh`: Deletes the stack.

These scripts will wrap the `aws cloudformation` CLI.

### Makefile
A root `Makefile` will provide high-level targets to interact with both modules:
- `make deploy-<module>`: Runs the `deploy.sh` script for the specified module.
- `make update-<module>`: Runs the `update.sh` script for the specified module.
- `make delete-<module>`: Runs the `delete.sh` script for the specified module.

Alternatively, we can use a parameter: `make deploy MODULE=devops-agent`. Given the user's example `make install devops-agent`, we will implement targets that allow specifying the module, or specific targets per module for clarity.

### Parameter Management
Parameters will be supplied via a `parameters.json` file in each module's `cfn/` directory. The format will be compatible with the `--parameters` flag of the AWS CLI:
```json
[
  {
    "ParameterKey": "AgentSpaceName",
    "ParameterValue": "MyAgentSpace"
  }
]
```

### Complex Types Handling
For complex Terraform variables like `github_repositories` (list of objects), the CloudFormation parameter will accept a JSON string, which will then be used in the resource definition.

## Risks / Trade-offs

- **[Risk]** IAM Propagation: CloudFormation sometimes returns "Success" before IAM roles are fully propagated, leading to "Access Denied" on dependent resources.
  - **Mitigation**: Use `DependsOn` consistently. If issues persist, add a small delay in the `deploy.sh` script between stack creation phases (though CloudFormation should handle this natively better than Terraform does with `time_sleep`).
- **[Risk]** Type Mismatch: Terraform's `awscc` provider might have nuances in how it handles certain attributes compared to raw CloudFormation.
  - **Mitigation**: Closely follow the AWS CloudFormation Resource Specification for `AWS::DevOpsAgent::AgentSpace` and `AWS::SecurityAgent::AgentSpace`.
