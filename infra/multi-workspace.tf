# Multi-Workspace Configuration for Unity Catalog Demo
# This file creates a second workspace to demonstrate cross-workspace data sharing

# Configure Databricks provider for analytics workspace
provider "databricks" {
  alias = "analytics"
  host  = azurerm_databricks_workspace.analytics.workspace_url
}

# Create second workspace for Analytics/Data Science (using public endpoint)
# Note: depends_on main workspace to avoid NAT Gateway race condition during parallel creation
resource "azurerm_databricks_workspace" "analytics" {
  name                          = "databricks-analytics-${var.environment}-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  sku                           = var.databricks_sku
  public_network_access_enabled = true
  # Must be unique and non-existent
  managed_resource_group_name = "databricks-analytics-mrg-${var.environment}-${random_string.suffix.result}"

  tags = merge(
    local.common_tags,
    {
      Purpose = "Analytics and Data Science"
    }
  )

  # Wait for main workspace to complete to avoid NAT Gateway conflicts
  depends_on = [
    azurerm_databricks_workspace.main,
    databricks_metastore.unity_catalog
  ]
}

# Assign the same Unity Catalog Metastore to Analytics Workspace
resource "databricks_metastore_assignment" "analytics_workspace" {
  provider     = databricks.accounts
  workspace_id = azurerm_databricks_workspace.analytics.workspace_id
  metastore_id = local.metastore_id

    # Wait for main workspace to complete
  depends_on = [
    azurerm_databricks_workspace.main,
    azurerm_databricks_workspace.analytics,
    databricks_metastore_assignment.workspace,
    databricks_metastore.unity_catalog
  ]
}



# # Assign the same Unity Catalog Metastore to Analytics Workspace
# resource "databricks_metastore_assignment" "analytics_workspace" {
#   provider     = databricks.accounts
#   workspace_id = azurerm_databricks_workspace.analytics.workspace_id
#   metastore_id = local.metastore_id

#   depends_on = [
#     databricks_metastore_assignment.workspace
#   ]
# }

# # Create Analytics Cluster in second workspace
# resource "databricks_cluster" "analytics_cluster" {
#   provider                = databricks.analytics
#   cluster_name            = "analytics-cluster-${var.environment}"
#   spark_version           = var.cluster_spark_version
#   node_type_id           = var.cluster_node_type
#   driver_node_type_id    = var.cluster_node_type
#   autotermination_minutes = 30
#   enable_elastic_disk     = true
#   data_security_mode     = "USER_ISOLATION"

#   autoscale {
#     min_workers = var.cluster_min_workers
#     max_workers = var.cluster_max_workers
#   }

#   spark_conf = {
#     "spark.databricks.delta.preview.enabled"              = "true"
#     "spark.databricks.cluster.profile"                   = "serverless"
#     "spark.databricks.repl.allowedLanguages"            = "python,sql,scala,r"
#     "spark.databricks.unity_catalog.enabled"            = "true"
#     "spark.serializer"                                   = "org.apache.spark.serializer.KryoSerializer"
#     "spark.sql.adaptive.enabled"                        = "true"
#     "spark.sql.adaptive.coalescePartitions.enabled"     = "true"
#   }

#   custom_tags = {
#     "Environment" = var.environment
#     "Project"     = "Azure Databricks BCDR"
#     "ManagedBy"   = "Terraform"
#     "Purpose"     = "Analytics Workspace Cluster"
#   }

#   depends_on = [
#     databricks_metastore_assignment.analytics_workspace,
#     databricks_catalog.main
#   ]
# }

# # Create a catalog specifically for shared data
# resource "databricks_catalog" "shared" {
#   provider      = databricks.workspace
#   name          = "shared_data"
#   comment       = "Shared catalog accessible across all workspaces"
#   force_destroy = true
  
#   # Provide storage location for catalogs when using existing metastore
#   storage_root  = "abfss://${azurerm_storage_container.unity_catalog.name}@${azurerm_storage_account.unity_catalog.name}.dfs.core.windows.net/catalogs/shared_data"

#   depends_on = [
#     databricks_metastore_assignment.workspace,
#     azurerm_role_assignment.unity_catalog_storage_blob_data_contributor
#   ]
# }

# # Create schema for sample datasets
# resource "databricks_schema" "samples" {
#   provider     = databricks.workspace
#   catalog_name = databricks_catalog.shared.name
#   name         = "samples"
#   comment      = "Sample datasets for demonstration"
#   force_destroy = true
# }

# # Grant access to shared catalog for analytics workspace users
# resource "databricks_grant" "shared_catalog_usage" {
#   provider   = databricks.workspace
#   catalog    = databricks_catalog.shared.name
#   principal  = "account users"
#   privileges = ["USE_CATALOG", "USE_SCHEMA"]
# }

# # Grant SELECT on shared schema for read access from analytics workspace
# resource "databricks_grant" "shared_schema_select" {
#   provider   = databricks.workspace
#   schema     = "${databricks_catalog.shared.name}.${databricks_schema.samples.name}"
#   principal  = "account users"
#   privileges = ["SELECT"]
# }