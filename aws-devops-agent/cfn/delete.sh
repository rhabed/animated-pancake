#!/bin/bash
set -e

STACK_NAME=${1:-"devops-agent-stack"}

echo "Deleting CloudFormation stack: $STACK_NAME..."

aws cloudformation delete-stack --stack-name "$STACK_NAME"
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"

echo "Deletion complete."
