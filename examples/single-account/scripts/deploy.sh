#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$EXAMPLE_DIR"

log() { echo "[$(date +%H:%M:%S)] $*"; }
err() { echo "[$(date +%H:%M:%S)] ERROR: $*" >&2; }

check_prereqs() {
  log "Checking prerequisites..."
  command -v terraform >/dev/null 2>&1 || { err "terraform not found. Install Terraform >= 1.0"; exit 1; }
  command -v aws >/dev/null 2>&1 || { err "aws CLI not found. Install and configure AWS CLI"; exit 1; }
  aws sts get-caller-identity >/dev/null 2>&1 || { err "AWS credentials not configured/expired."; exit 1; }
}

ensure_tfvars() {
  if [[ ! -f terraform.tfvars ]]; then
    if [[ -f terraform.tfvars.example ]]; then
      log "Creating terraform.tfvars from terraform.tfvars.example"
      cp terraform.tfvars.example terraform.tfvars
      log "Edit terraform.tfvars if needed, then re-run this script."
    else
      err "terraform.tfvars not found and no terraform.tfvars.example to copy."
      exit 1
    fi
  fi
}

run_terraform() {
  log "terraform init"
  terraform init -input=false

  log "terraform validate"
  terraform validate

  log "terraform apply"
  terraform apply -input=false
}

main() {
  check_prereqs
  ensure_tfvars
  run_terraform
  log "Done. Run ./scripts/post-deploy.sh for next steps."
}

main "$@"

