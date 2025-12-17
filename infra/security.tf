# Security and Role Assignments
# This file configures security roles and permissions

# Role assignment for Databricks workspace admin
resource "azurerm_role_assignment" "databricks_workspace_admin" {
  scope                = azurerm_databricks_workspace.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.databricks.principal_id
}

# Role assignment for Key Vault access
resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.databricks.principal_id
}

# Role assignment for storage account access (for general Databricks operations)
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.databricks.principal_id
}

# Role assignment for Terraform identity to manage storage account
# This allows Terraform to read storage properties using Azure AD auth instead of access keys
resource "azurerm_role_assignment" "terraform_storage_contributor" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Diagnostic settings for security monitoring
resource "azurerm_monitor_diagnostic_setting" "databricks_workspace" {
  name                       = "databricks-diagnostics"
  target_resource_id         = azurerm_databricks_workspace.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "dbfs"
  }

  enabled_log {
    category = "clusters"
  }

  enabled_log {
    category = "accounts"
  }

  enabled_log {
    category = "jobs"
  }

  enabled_log {
    category = "notebook"
  }

  # metric {
  #   category = "AllMetrics"
  #   enabled  = true
  # }
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-databricks-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}
