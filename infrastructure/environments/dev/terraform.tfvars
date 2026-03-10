###############################################################################
# Dev Environment Configuration
#
# Usage: terraform plan -var-file="environments/dev/terraform.tfvars"
###############################################################################

project_name = "graph-rag"
environment  = "dev"
location     = "westeurope"   # Change to your nearest region

# Set these via environment variables for security:
#   export TF_VAR_openai_api_key="sk-..."
#   export TF_VAR_openai_api_base_url="https://api.openai.com/v1"
