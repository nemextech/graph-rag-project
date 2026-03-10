###############################################################################
# Input Variables
###############################################################################

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "graph-rag"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens only."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "openai_api_key" {
  description = "OpenAI API key (or Azure OpenAI key) for LLM calls"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_base_url" {
  description = "Base URL for OpenAI-compatible API. Use default for OpenAI, or set Azure OpenAI endpoint."
  type        = string
  default     = "https://api.openai.com/v1"
}
