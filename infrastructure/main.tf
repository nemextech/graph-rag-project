###############################################################################
# Graph-RAG Project - Main Infrastructure
# 
# This is the root module that orchestrates all Azure resources needed for
# the Graph-RAG document Q&A system.
#
# Architecture:
#   - Azure Blob Storage: Document ingestion & storage
#   - Azure Cosmos DB (MongoDB API): Document chunks, metadata, embeddings
#   - Azure Cosmos DB (Gremlin API): Knowledge graph of entities
#   - Azure Container Apps: FastAPI application hosting
#   - Azure Application Insights: Monitoring & observability
#   - Azure OpenAI (optional): LLM for production use
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }

  # Uncomment this when ready to use remote state (recommended for CI/CD)
  # backend "azurerm" {
  #   resource_group_name  = "rg-graph-rag-tfstate"
  #   storage_account_name = "stgraphragtfstate"
  #   container_name       = "tfstate"
  #   key                  = "dev.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Modules
# -----------------------------------------------------------------------------

module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = local.common_tags
}

module "cosmosdb" {
  source = "./modules/cosmosdb"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = local.common_tags
}

module "container_app" {
  source = "./modules/container_app"

  resource_group_name            = azurerm_resource_group.main.name
  location                       = azurerm_resource_group.main.location
  project_name                   = var.project_name
  environment                    = var.environment
  tags                           = local.common_tags
  log_analytics_workspace_id     = module.monitoring.log_analytics_workspace_id
  application_insights_connection_string = module.monitoring.application_insights_connection_string
  cosmos_mongodb_connection_string       = module.cosmosdb.mongodb_connection_string
  cosmos_gremlin_endpoint               = module.cosmosdb.gremlin_endpoint
  cosmos_gremlin_primary_key            = module.cosmosdb.gremlin_primary_key
  storage_account_connection_string     = module.storage.connection_string
  openai_api_key                        = var.openai_api_key
  openai_api_base_url                   = var.openai_api_base_url
}
