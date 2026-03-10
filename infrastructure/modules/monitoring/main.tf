###############################################################################
# Monitoring Module - Application Insights & Log Analytics
#
# Provides:
#   - Log Analytics Workspace: Central log aggregation
#   - Application Insights: APM for the FastAPI application
#
# This gives you request tracing, custom metrics for RAG performance,
# and dashboards out of the box.
###############################################################################

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30  # Minimum for cost savings

  tags = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "application_insights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}
