###############################################################################
# Storage Module - Azure Blob Storage for Document Ingestion
#
# Containers:
#   - documents:  Raw uploaded documents (PDFs, text files)
#   - processed:  Chunked and processed document data
#   - embeddings: Cached embedding vectors (optional backup)
###############################################################################

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "project_name" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }

# Storage account names must be 3-24 chars, lowercase alphanumeric only
resource "azurerm_storage_account" "documents" {
  name                     = "st${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Security best practices
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    # auto-delete processed temp files after 7 days
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_id  = azurerm_storage_account.documents.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "processed" {
  name                  = "processed"
  storage_account_id  = azurerm_storage_account.documents.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "storage_account_name" {
  value = azurerm_storage_account.documents.name
}

output "connection_string" {
  value     = azurerm_storage_account.documents.primary_connection_string
  sensitive = true
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.documents.primary_blob_endpoint
}
