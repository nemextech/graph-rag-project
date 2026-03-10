###############################################################################
# Cosmos DB Module
#
# This provisions TWO Cosmos DB accounts:
#   1. MongoDB API  - Document chunks, metadata, and vector embeddings
#   2. Gremlin API  - Knowledge graph of entities and relationships
#
# Both use serverless capacity mode for cost optimization during development.
# Switch to provisioned throughput for production workloads.
###############################################################################

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }

# =============================================================================
# Cosmos DB Account - MongoDB API (Documents & Embeddings)
# =============================================================================
resource "azurerm_cosmosdb_account" "mongodb" {
  name                = "cosmos-${var.project_name}-mongo-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = "Standard"
  kind                = "MongoDB"

  # Serverless = pay only for what you use
  capabilities {
    name = "EnableServerless"
  }

  capabilities {
    name = "EnableMongo"
  }

  # Vector search support for embeddings
  capabilities {
    name = "EnableMongoDBVectorSearch"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = var.tags
}

# MongoDB Database
resource "azurerm_cosmosdb_mongo_database" "main" {
  name                = "graph-rag-db"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.mongodb.name
}

# Collection: Document chunks with vector index for embeddings
resource "azurerm_cosmosdb_mongo_collection" "chunks" {
  name                = "document_chunks"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.mongodb.name
  database_name       = azurerm_cosmosdb_mongo_database.main.name

  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys = ["document_id"]
  }

  index {
    keys = ["source"]
  }
}

# Collection: Document metadata (tracking ingested files)
resource "azurerm_cosmosdb_mongo_collection" "documents" {
  name                = "documents"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.mongodb.name
  database_name       = azurerm_cosmosdb_mongo_database.main.name

  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys = ["filename"]
  }
}

# =============================================================================
# Cosmos DB Account - Gremlin API (Knowledge Graph)
# =============================================================================
resource "azurerm_cosmosdb_account" "gremlin" {
  name                = "cosmos-${var.project_name}-graph-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  capabilities {
    name = "EnableGremlin"
  }

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = var.tags
}

# Gremlin Database
resource "azurerm_cosmosdb_gremlin_database" "main" {
  name                = "knowledge-graph"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.gremlin.name
}

# Gremlin Graph: Entities and their relationships
resource "azurerm_cosmosdb_gremlin_graph" "entities" {
  name                = "entities"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.gremlin.name
  database_name       = azurerm_cosmosdb_gremlin_database.main.name
  partition_key_path  = "/category"

  index_policy {
    automatic      = true
    indexing_mode  = "consistent"
    included_paths = ["/*"]
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "mongodb_connection_string" {
  value     = azurerm_cosmosdb_account.mongodb.primary_mongodb_connection_string
  sensitive = true
}

output "gremlin_endpoint" {
  value = azurerm_cosmosdb_account.gremlin.endpoint
}

output "gremlin_primary_key" {
  value     = azurerm_cosmosdb_account.gremlin.primary_key
  sensitive = true
}

output "mongodb_account_name" {
  value = azurerm_cosmosdb_account.mongodb.name
}

output "gremlin_account_name" {
  value = azurerm_cosmosdb_account.gremlin.name
}
