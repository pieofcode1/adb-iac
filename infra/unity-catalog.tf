# Unity Catalog Configuration
# This file configures Unity Catalog metastore and related resources

# Configure Databricks provider for account-level operations
provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id
}

# Configure Databricks provider for workspace-level operations
provider "databricks" {
  alias = "workspace"
  host  = azurerm_databricks_workspace.main.workspace_url
}

# Local value to determine which metastore ID to use
locals {
  metastore_id = var.existing_metastore_id != "" ? var.existing_metastore_id : (length(databricks_metastore.unity_catalog) > 0 ? databricks_metastore.unity_catalog[0].id : null)
  # Use the existing main catalog name when using existing metastore, otherwise use the created catalog
  # main_catalog_name = var.existing_metastore_id != "" ? "main" : (length(databricks_catalog.main) > 0 ? databricks_catalog.main[0].name : "main")
  main_catalog_name = "main"
}

# Create Unity Catalog Metastore (Account-level resource) - only if no existing metastore is provided
resource "databricks_metastore" "unity_catalog" {
  count         = var.existing_metastore_id == "" ? 1 : 0
  provider      = databricks.accounts
  name          = "metastore-${var.environment}-${random_string.suffix.result}"
  storage_root  = "abfss://${azurerm_storage_container.unity_catalog.name}@${azurerm_storage_account.unity_catalog.name}.dfs.core.windows.net/"
  region        = var.metastore_region
  force_destroy = true

  depends_on = [
    azurerm_role_assignment.unity_catalog_storage_blob_data_contributor
  ]
}

# Create Unity Catalog Metastore Data Access Configuration - only for new metastores
resource "databricks_metastore_data_access" "unity_catalog" {
  count        = var.existing_metastore_id == "" ? 1 : 0
  provider     = databricks.accounts
  metastore_id = databricks_metastore.unity_catalog[0].id
  name         = "unity-catalog-access-${random_string.suffix.result}"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity_catalog.id
  }
  is_default = true

  # Prevent deletion errors - the metastore must be deleted first
  lifecycle {
    create_before_destroy = true
  }
}

# Assign Unity Catalog Metastore to Workspace
resource "databricks_metastore_assignment" "workspace" {
  provider     = databricks.accounts
  workspace_id = azurerm_databricks_workspace.main.workspace_id
  metastore_id = local.metastore_id
}


# Set default catalog using the recommended resource
resource "databricks_default_namespace_setting" "default_catalog" {
  provider = databricks.workspace
  namespace {
    value = local.main_catalog_name
  }
  depends_on = [
    databricks_metastore_assignment.workspace, 
    # databricks_catalog.main
  ]
}

# Create Databricks Access Connector for Unity Catalog
resource "azurerm_databricks_access_connector" "unity_catalog" {
  name                = "dac-unity-catalog-${var.environment}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Role assignment for Unity Catalog access to storage
resource "azurerm_role_assignment" "unity_catalog_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity_catalog.identity[0].principal_id
}

# Create default catalog in Unity Catalog - only if creating a new metastore
# When using an existing metastore, the 'main' catalog already exists
# resource "databricks_catalog" "main" {
#   count         = var.existing_metastore_id == "" ? 1 : 0
#   provider      = databricks.workspace
#   name          = "main"
#   comment       = "Main catalog for ${var.environment} environment"
#   force_destroy = true
  
#   # Provide storage location for catalogs when using existing metastore
#   storage_root  = "abfss://${azurerm_storage_container.unity_catalog.name}@${azurerm_storage_account.unity_catalog.name}.dfs.core.windows.net/catalogs/main"

#   depends_on = [
#     databricks_metastore_assignment.workspace,
#     azurerm_role_assignment.unity_catalog_storage_blob_data_contributor
#   ]
# }

# # Create default schema in the main catalog - only if creating a new metastore
# # When using an existing metastore, the 'default' schema likely already exists
# resource "databricks_schema" "default" {
#   count         = var.existing_metastore_id == "" ? 1 : 0
#   provider      = databricks.workspace
#   catalog_name  = local.main_catalog_name
#   name          = "default"
#   comment       = "Default schema for ${var.environment} environment"
#   force_destroy = true

#   depends_on = [
#     databricks_metastore_assignment.workspace,
#     # databricks_catalog.main
#   ]
# }

# Grant Unity Catalog admin permissions to specified users
# Only create grants for new metastores - existing metastores may already have permissions
resource "databricks_grant" "metastore_admin" {
  provider   = databricks.workspace
  count      = var.existing_metastore_id == "" ? length(var.unity_catalog_admin_users) : 0
  metastore  = local.metastore_id
  principal  = var.unity_catalog_admin_users[count.index]
  privileges = ["CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION"]

  depends_on = [
    databricks_metastore_assignment.workspace
  ]
}

# Grant catalog usage permissions to admin users
# Only create grants for new catalogs - existing catalogs may already have permissions
resource "databricks_grant" "catalog_usage" {
  provider   = databricks.workspace
  count      = var.existing_metastore_id == "" ? length(var.unity_catalog_admin_users) : 0
  catalog    = local.main_catalog_name
  principal  = var.unity_catalog_admin_users[count.index]
  privileges = ["USE_CATALOG", "USE_SCHEMA", "CREATE_SCHEMA"]

  depends_on = [
    databricks_metastore_assignment.workspace,
    # databricks_catalog.main
  ]
}
