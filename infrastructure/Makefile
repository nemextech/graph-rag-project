###############################################################################
# Infrastructure Makefile
#
# Quick commands for common Terraform operations.
# Usage:  cd infrastructure && make plan
###############################################################################

.PHONY: init plan apply destroy fmt validate clean

ENV ?= dev
VAR_FILE = environments/$(ENV)/terraform.tfvars

# Initialize Terraform (download providers, set up backend)
init:
	terraform init

# Format all .tf files (run before every commit)
fmt:
	terraform fmt -recursive

# Validate syntax and configuration
validate:
	terraform validate

# Preview what will change
plan: fmt validate
	terraform plan -var-file="$(VAR_FILE)" -out=tfplan

# Apply the changes
apply:
	terraform apply tfplan

# Destroy all resources (careful!)
destroy:
	terraform destroy -var-file="$(VAR_FILE)"

# Clean up local Terraform files
clean:
	rm -rf .terraform tfplan .terraform.lock.hcl

# Show current state
show:
	terraform show

# Full cycle: init -> plan -> apply
deploy: init plan apply

# Output all values
outputs:
	terraform output
