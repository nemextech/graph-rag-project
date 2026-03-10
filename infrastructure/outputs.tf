###############################################################################
# Outputs
###############################################################################

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the storage account for documents"
  value       = module.storage.storage_account_name
}

output "cosmos_mongodb_connection_string" {
  description = "Cosmos DB MongoDB API connection string"
  value       = module.cosmosdb.mongodb_connection_string
  sensitive   = true
}

output "cosmos_gremlin_endpoint" {
  description = "Cosmos DB Gremlin API endpoint"
  value       = module.cosmosdb.gremlin_endpoint
}

output "container_app_url" {
  description = "URL of the deployed Container App"
  value       = module.container_app.app_url
}

output "application_insights_connection_string" {
  description = "Application Insights connection string for monitoring"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}
