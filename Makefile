.PHONY: deploy-devops update-devops delete-devops validate-devops deploy-security update-security delete-security validate-security validate help

help:
	@echo "Available commands:"
	@echo "  make validate           - Validate all CloudFormation templates"
	@echo "  make validate-devops    - Validate DevOps Agent template"
	@echo "  make validate-security  - Validate Security Agent template"
	@echo "  make deploy-devops      - Deploy DevOps Agent stack"
	@echo "  make update-devops      - Update DevOps Agent stack"
	@echo "  make delete-devops      - Delete DevOps Agent stack"
	@echo "  make deploy-security    - Deploy Security Agent stack"
	@echo "  make update-security    - Update Security Agent stack"
	@echo "  make delete-security    - Delete Security Agent stack"

validate: validate-devops validate-security

validate-devops:
	aws cloudformation validate-template --template-body file://aws-devops-agent/cfn/template.yaml

validate-security:
	aws cloudformation validate-template --template-body file://aws-security-agent/cfn/template.yaml

deploy-devops:
	@cd aws-devops-agent/cfn && ./deploy.sh

update-devops:
	@cd aws-devops-agent/cfn && ./update.sh

delete-devops:
	@cd aws-devops-agent/cfn && ./delete.sh

deploy-security:
	@cd aws-security-agent/cfn && ./deploy.sh

update-security:
	@cd aws-security-agent/cfn && ./update.sh

delete-security:
	@cd aws-security-agent/cfn && ./delete.sh
