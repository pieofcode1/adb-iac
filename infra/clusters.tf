# Databricks Cluster Configuration
# This file creates a Databricks cluster with Unity Catalog support

# Create Databricks cluster
resource "databricks_cluster" "unity_catalog_cluster" {
  provider                = databricks.workspace
  cluster_name            = "unity-catalog-cluster-${var.environment}"
  spark_version           = var.cluster_spark_version
  node_type_id            = var.cluster_node_type
  driver_node_type_id     = var.cluster_node_type
  autotermination_minutes = 30
  enable_elastic_disk     = true
  data_security_mode      = "USER_ISOLATION" # Required for Unity Catalog

  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }

  spark_conf = {
    # Performance optimizations
    "spark.databricks.delta.preview.enabled"        = "true"
    "spark.serializer"                              = "org.apache.spark.serializer.KryoSerializer"
    "spark.sql.adaptive.enabled"                    = "true"
    "spark.sql.adaptive.coalescePartitions.enabled" = "true"
  }
  library {
    pypi {
      package = "pandas"
    }
  }

  library {
    pypi {
      package = "numpy"
    }
  }

  library {
    pypi {
      package = "scikit-learn"
    }
  }
  custom_tags = {
    "Environment" = var.environment
    "Project"     = "Azure Databricks BCDR"
    "ManagedBy"   = "Terraform"
    "Purpose"     = "Unity Catalog Cluster"
  }

  depends_on = [
    databricks_metastore_assignment.workspace
  ]
}

# # Create a shared cluster for collaborative work
# resource "databricks_cluster" "shared_cluster" {
#   provider                = databricks.workspace
#   cluster_name            = "shared-cluster-${var.environment}"
#   spark_version           = var.cluster_spark_version
#   node_type_id            = var.cluster_node_type
#   driver_node_type_id     = var.cluster_node_type
#   autotermination_minutes = 60
#   enable_elastic_disk     = true
#   data_security_mode      = "SHARED" # Shared mode for collaborative work

#   autoscale {
#     min_workers = var.cluster_min_workers
#     max_workers = var.cluster_max_workers
#   }

#   spark_conf = {
#     # Performance optimizations
#     "spark.databricks.delta.preview.enabled"        = "true"
#     "spark.serializer"                              = "org.apache.spark.serializer.KryoSerializer"
#     "spark.sql.adaptive.enabled"                    = "true"
#     "spark.sql.adaptive.coalescePartitions.enabled" = "true"
#   }

#   library {
#     pypi {
#       package = "pandas"
#     }
#   }

#   library {
#     pypi {
#       package = "numpy"
#     }
#   }

#   library {
#     pypi {
#       package = "scikit-learn"
#     }
#   }

#   custom_tags = {
#     "Environment" = var.environment
#     "Project"     = "Azure Databricks BCDR"
#     "ManagedBy"   = "Terraform"
#     "Purpose"     = "Shared Cluster"
#   }

#   depends_on = [
#     databricks_metastore_assignment.workspace
#   ]
# }

# Create a SQL warehouse for analytics
resource "databricks_sql_endpoint" "analytics" {
  provider         = databricks.workspace
  name             = "analytics-warehouse-${var.environment}"
  cluster_size     = "2X-Small"
  auto_stop_mins   = 30
  enable_serverless_compute = false  # Use classic SQL warehouse for more stability
  warehouse_type   = "CLASSIC"       # Explicitly set warehouse type
  
  # Increase timeout for warehouse startup - SQL warehouses can take time in new workspaces
  timeouts {
    create = "90m"
  }

  tags {
    custom_tags {
      key   = "Environment"
      value = var.environment
    }
    custom_tags {
      key   = "Project"
      value = "Azure Databricks BCDR"
    }
    custom_tags {
      key   = "ManagedBy"
      value = "Terraform"
    }
  }

  # Wait for clusters to be ready first - they validate workspace connectivity
  depends_on = [
    databricks_metastore_assignment.workspace,
    databricks_cluster.unity_catalog_cluster
  ]
}
