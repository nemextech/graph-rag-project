# Infrastructure

Terraform configuration for provisioning all Azure resources needed by the Graph-RAG project. Uses a modular design with environment-based variable files for clean separation between dev, staging, and production.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                Azure Resource Group                  │
│               rg-graph-rag-{env}                     │
│                                                      │
│  ┌──────────────┐  ┌────────────────────────────┐   │
│  │ Blob Storage  │  │     Cosmos DB (MongoDB)     │   │
│  │ st*graphrag*  │  │  Serverless · Vector Search │   │
│  │               │  │                             │   │
│  │ ○ documents   │  │  ○ document_chunks          │   │
│  │ ○ processed   │  │  ○ documents (metadata)     │   │
│  └──────────────┘  └────────────────────────────┘   │
│                                                      │
│  ┌────────────────────────────┐  ┌───────────────┐  │
│  │   Cosmos DB (Gremlin)      │  │  Container App │  │
│  │  Serverless · Graph API    │  │  FastAPI · 8000│  │
│  │                            │  │  Scale to zero │  │
│  │  ○ entities graph          │  │                │  │
│  └────────────────────────────┘  └───────────────┘  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │         Application Insights                    │  │
│  │         + Log Analytics Workspace               │  │
│  └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Module Structure

```
infrastructure/
├── main.tf                          # Root module — orchestrates all resources
├── variables.tf                     # Input variables with validation
├── outputs.tf                       # Values exported after deployment
├── locals.tf                        # Common tags, computed values
├── Makefile                         # Helper commands
├── .gitignore                       # Terraform-specific ignores
├── environments/
│   └── dev/
│       └── terraform.tfvars         # Dev-specific variable values
└── modules/
    ├── storage/
    │   └── main.tf                  # Azure Blob Storage (documents + processed)
    ├── cosmosdb/
    │   └── main.tf                  # Two Cosmos DB accounts (MongoDB + Gremlin)
    ├── container_app/
    │   └── main.tf                  # Container Apps environment + app
    └── monitoring/
        └── main.tf                  # Log Analytics + Application Insights
```

## Resources Provisioned

| Module | Resource | SKU / Mode | Purpose |
|--------|----------|-----------|---------|
| `storage` | Azure Blob Storage | Standard LRS | Raw and processed document storage |
| `cosmosdb` | Cosmos DB (MongoDB API) | Serverless | Document chunks, metadata, vector embeddings |
| `cosmosdb` | Cosmos DB (Gremlin API) | Serverless | Knowledge graph of entities and relationships |
| `container_app` | Container Apps Environment | Consumption | Shared infrastructure for containers |
| `container_app` | Container App | 1 vCPU / 2Gi | FastAPI application (scales 0–3 replicas) |
| `monitoring` | Log Analytics Workspace | PerGB2018, 30-day retention | Central log aggregation |
| `monitoring` | Application Insights | Web | APM, request tracing, custom metrics |

## Cost Optimization

All resources are configured for minimal cost during development:

- **Cosmos DB Serverless** — pay per request instead of provisioned RU/s. Ideal when traffic is low or bursty. Two accounts cost near-zero when idle.
- **Container Apps scale to zero** — `min_replicas = 0` means no compute charges when the app isn't receiving traffic.
- **Storage LRS** — locally redundant storage is the cheapest replication option. Sufficient for dev/showcase.
- **Log Analytics 30-day retention** — minimum retention period to keep costs low.

**Estimated monthly cost with light dev usage: ~$5–15.**

To reduce further, you can destroy resources when not actively developing: `make destroy`.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`)
- An Azure subscription with Contributor access

## Quick Start

```bash
# 1. Authenticate with Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# 2. Set sensitive variables (don't put these in tfvars)
export TF_VAR_openai_api_key="sk-..."        # If using OpenAI
# Or leave empty if using Ollama locally

# 3. Initialize Terraform
cd infrastructure
make init

# 4. Review the execution plan
make plan

# 5. Apply (creates all resources)
make apply
```

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make init` | Initialize Terraform, download providers |
| `make fmt` | Format all `.tf` files |
| `make validate` | Validate configuration syntax |
| `make plan` | Preview changes (auto-formats and validates first) |
| `make apply` | Apply the saved plan |
| `make destroy` | Tear down all resources |
| `make show` | Show current Terraform state |
| `make outputs` | Display all output values |
| `make deploy` | Full cycle: init → plan → apply |

All commands default to the `dev` environment. Override with: `make plan ENV=staging`

## Secrets Management

Sensitive values are handled securely:

- **Terraform variables** — passed via `TF_VAR_*` environment variables, never committed to tfvars files
- **Container App** — secrets stored in Azure Container Apps secret store, referenced by environment variables
- **State file** — contains sensitive outputs; use remote backend (Azure Storage) with encryption for team use

To enable remote state, uncomment the `backend` block in `main.tf` and create the storage account:

```bash
az group create -n rg-graph-rag-tfstate -l westeurope
az storage account create -n stgraphragtfstate -g rg-graph-rag-tfstate -l westeurope --sku Standard_LRS
az storage container create -n tfstate --account-name stgraphragtfstate
```

## Adding a New Environment

1. Create `environments/staging/terraform.tfvars`
2. Adjust values (location, naming, etc.)
3. Run: `make plan ENV=staging`

## Extending

To add a new Azure resource:

1. Create a new module under `modules/your_resource/main.tf`
2. Define variables, resource blocks, and outputs
3. Wire it into `main.tf` as a module call
4. Add any new outputs to `outputs.tf`
