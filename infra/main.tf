# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.55.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "=1.99.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
  required_version = ">= 1.0"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "569c92fe-efb6-440d-9274-73860e3f69aa"
  # Use Azure AD authentication for storage account operations instead of access keys
  storage_use_azuread = true
}

# # Configure Databricks provider for analytics workspace
# provider "databricks" {
#   alias = "analytics"
#   host  = azurerm_databricks_workspace.main.workspace_url
# }

# Generate a random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-databricks-${var.environment}-${random_string.suffix.result}"
  location = var.location

  tags = local.common_tags
}

# Create Storage Account for Unity Catalog Metastore
resource "azurerm_storage_account" "unity_catalog" {
  name                     = "st${replace(var.environment, "-", "")}uc${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Hierarchical namespace for Data Lake Gen2
  shared_access_key_enabled = false # Disable key-based authentication, use Azure AD only

  tags = local.common_tags
}

# Create Storage Container for Unity Catalog
resource "azurerm_storage_container" "unity_catalog" {
  name                  = "unity-catalog"
  storage_account_id    = azurerm_storage_account.unity_catalog.id
  container_access_type = "private"
}

# Create Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-databricks-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled  = false

  tags = local.common_tags
}

# Create User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "databricks" {
  name                = "mi-databricks-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Create Databricks Workspace (using public endpoint - no custom VNet injection)
resource "azurerm_databricks_workspace" "main" {
  name                        = "databricks-${var.environment}-${random_string.suffix.result}"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = var.databricks_sku
  public_network_access_enabled = true

  tags = local.common_tags
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = "Azure Databricks BCDR"
    ManagedBy   = "Terraform"
  }
}
