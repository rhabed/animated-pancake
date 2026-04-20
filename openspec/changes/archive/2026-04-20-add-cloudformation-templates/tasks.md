## 1. DevOps Agent CloudFormation Port

- [x] 1.1 Create `aws-devops-agent/cfn/template.yaml` with IAM roles and policies <!-- id: task-1.1 -->
- [x] 1.2 Implement `AWS::DevOpsAgent::AgentSpace` resource in the template <!-- id: task-1.2 -->
- [x] 1.3 Add stack management scripts: `deploy.sh`, `update.sh`, `delete.sh` in `aws-devops-agent/cfn/` <!-- id: task-1.3 -->
- [x] 1.4 Create `aws-devops-agent/cfn/parameters.json.example` <!-- id: task-1.4 -->

## 2. Security Agent CloudFormation Port

- [x] 2.1 Create `aws-security-agent/cfn/template.yaml` with IAM roles and policies <!-- id: task-2.1 -->
- [x] 2.2 Implement `AWS::SecurityAgent::AgentSpace` resource in the template <!-- id: task-2.2 -->
- [x] 2.3 Add stack management scripts: `deploy.sh`, `update.sh`, `delete.sh` in `aws-security-agent/cfn/` <!-- id: task-2.3 -->
- [x] 2.4 Create `aws-security-agent/cfn/parameters.json.example` <!-- id: task-2.4 -->

## 3. Verification

- [x] 3.1 Validate templates using `aws cloudformation validate-template` <!-- id: task-3.1 -->
- [x] 3.2 Verify management scripts are executable and follow the design <!-- id: task-3.2 -->

## 4. Root Makefile Implementation

- [x] 4.1 Create `Makefile` at the repository root <!-- id: task-4.1 -->
- [x] 4.2 Implement targets for `deploy`, `update`, and `delete` for both modules <!-- id: task-4.2 -->
