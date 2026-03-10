###############################################################################
# Container App Module - Serverless Application Hosting
#
# The app receives all connection strings as environment variables,
# following 12-factor app principles.
###############################################################################

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }
variable "log_analytics_workspace_id" { type = string }
variable "application_insights_connection_string" {
  type      = string
  sensitive = true
}
variable "cosmos_mongodb_connection_string" {
  type      = string
  sensitive = true
}
variable "cosmos_gremlin_endpoint" { type = string }
variable "cosmos_gremlin_primary_key" {
  type      = string
  sensitive = true
}
variable "storage_account_connection_string" {
  type      = string
  sensitive = true
}
variable "openai_api_key" {
  type      = string
  sensitive = true
  default   = ""
}
variable "openai_api_base_url" {
  type    = string
  default = "https://api.openai.com/v1"
}

# Container Apps Environment (shared infrastructure)
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project_name}-${var.environment}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = var.tags
}

# The Container App itself
resource "azurerm_container_app" "api" {
  name                         = "ca-${var.project_name}-api-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"

  tags = var.tags

  # NOTE: Initially we use a placeholder image. Your CI/CD pipeline will
  # update this to your actual image from GitHub Container Registry.
  template {
    min_replicas = 0  # Scale to zero when idle
    max_replicas = 3

    container {
      name   = "graph-rag-api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 1.0
      memory = "2Gi"

      # Application configuration via environment variables
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name        = "COSMOS_MONGODB_CONNECTION_STRING"
        secret_name = "cosmos-mongodb-conn"
      }

      env {
        name  = "COSMOS_GREMLIN_ENDPOINT"
        value = var.cosmos_gremlin_endpoint
      }

      env {
        name        = "COSMOS_GREMLIN_PRIMARY_KEY"
        secret_name = "cosmos-gremlin-key"
      }

      env {
        name        = "AZURE_STORAGE_CONNECTION_STRING"
        secret_name = "storage-conn"
      }

      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-api-key"
      }

      env {
        name  = "OPENAI_API_BASE_URL"
        value = var.openai_api_base_url
      }

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-conn"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000  # FastAPI default
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Secrets (referenced by env vars above)
  secret {
    name  = "cosmos-mongodb-conn"
    value = var.cosmos_mongodb_connection_string
  }

  secret {
    name  = "cosmos-gremlin-key"
    value = var.cosmos_gremlin_primary_key
  }

  secret {
    name  = "storage-conn"
    value = var.storage_account_connection_string
  }

  secret {
    name  = "openai-api-key"
    value = var.openai_api_key
  }

  secret {
    name  = "appinsights-conn"
    value = var.application_insights_connection_string
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "app_url" {
  value = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "container_app_name" {
  value = azurerm_container_app.api.name
}
