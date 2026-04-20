---
trigger: always_on
---

# Environment & Terminal Rules

## Python Virtual Environment
- **Context**: This project uses a local virtual environment for all dependencies.
- **Rule**: ALWAYS execute python scripts using the interpreter at `./.venv/bin/python` instead of the system `python3`.
- **Constraint**: If running `pip`, always use `./.venv/bin/pip`.

## AWS Credentials & CLI
- **Context**: AWS commands require specific profile authorization.
- **Rule**: Before running any `aws` CLI command, check if `AWS_PROFILE` is set.
- **Action**: If not set, prefix commands with `AWS_PROFILE=rhabed` or ask the user which profile to use.
- **Path**: Ensure the agent looks for AWS config in the standard `~/.aws/` directory.

## Shell Initialization
- **Rule**: When opening a new shell session to run commands, explicitly source the local environment if needed: `source .venv/bin/activate`.
- **Restriction**: Do not attempt to install global system packages; stay within the workspace boundaries.
