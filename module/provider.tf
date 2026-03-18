# ------------------------------------------------------------------------------
# Provider configuration (optional)
# - Callers can also configure providers in the root module and pass them down.
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

provider "awscc" {
  region = var.aws_region
}

