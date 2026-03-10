# Infrastructure

Terraform configuration for the Graph-RAG project on Azure.

## Architecture

| Resource | Service | Purpose |
|----------|---------|---------|
| Document Storage | Azure Blob Storage (LRS) | Store raw and processed documents |
| Document DB | Cosmos DB (MongoDB API, serverless) | Chunks, metadata, vector embeddings |
| Knowledge Graph | Cosmos DB (Gremlin API, serverless) | Entity-relationship graph |
| Application | Azure Container Apps | FastAPI hosting (scales to zero) |
| Monitoring | Application Insights + Log Analytics | APM, logging, custom metrics |

## Cost Optimization

All resources use the cheapest viable tiers for development:
- **Cosmos DB**: Serverless mode (pay per request, not provisioned RU/s)
- **Container Apps**: Scale to zero when idle
- **Storage**: LRS replication (single region)
- **Log Analytics**: 30-day retention

Estimated dev cost: **~$5-15/month** with light usage.

## Quick Start

```bash
# 1. Login to Azure
az login

# 2. Set your OpenAI key (if using OpenAI API)
export TF_VAR_openai_api_key="sk-..."

# 3. Initialize and deploy
cd infrastructure
make init
make plan    # Review what will be created
make apply   # Create the resources
```

## Module Structure

```
infrastructure/
├── main.tf                    # Root module - orchestrates everything
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── locals.tf                  # Common tags and computed values
├── Makefile                   # Helper commands
├── environments/
│   └── dev/
│       └── terraform.tfvars   # Dev environment values
└── modules/
    ├── storage/               # Blob Storage for documents
    ├── cosmosdb/              # MongoDB + Gremlin databases
    ├── container_app/         # Container Apps hosting
    └── monitoring/            # Application Insights + Log Analytics
```
