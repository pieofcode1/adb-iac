# Azure Databricks with Unity Catalog - Terraform Infrastructure

This repository contains Terraform infrastructure as code for deploying Azure Databricks workspace with Unity Catalog support.

## Architecture Overview

The infrastructure includes:
- **2 Azure Databricks Workspaces** with Premium SKU (Data Engineering + Analytics)
- **Unity Catalog** with dedicated metastore and shared storage
- **Storage Account** (ADLS Gen2) for Unity Catalog metastore
- **Key Vault** for secrets management
- **Access Connector** for Unity Catalog authentication
- **Managed Identity** for secure access
- **Databricks Clusters** (Unity Catalog enabled)
- **Log Analytics** for monitoring and diagnostics

> **Network Configuration**: This solution uses **public endpoints** by default for simplicity and faster deployment. For production environments requiring enhanced security, VNet injection with private endpoints can be added.

## Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** - [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
3. **Azure Subscription** with appropriate permissions
4. **Databricks Account** - You'll need the Databricks Account ID for Unity Catalog

## Getting Started

### 1. Authentication

Login to Azure:
```bash
az login
```

Set your subscription:
```bash
az account set --subscription "your-subscription-id"
```

### 2. Get Databricks Account ID

1. Go to [Databricks Account Console](https://accounts.azuredatabricks.net/)
2. Copy your Account ID from the URL or account settings
3. This will be needed for Unity Catalog configuration

### 3. Configure Variables

1. Copy `terraform.tfvars` to create your environment-specific configuration
2. Update the variables with your specific values:

```hcl
# Basic configuration
environment = "dev"
location    = "East US"

# Unity Catalog admin users
unity_catalog_admin_users = [
  "admin@yourdomain.com",
  "data-engineer@yourdomain.com"
]

# Network security (optional)
allowed_ip_ranges = [
  "203.0.113.0/24"  # Your office network
]
```

3. Set your Databricks Account ID as an environment variable:
```bash
export TF_VAR_databricks_account_id="your-databricks-account-id"
```

Or add it to your `.tfvars` file:
```hcl
databricks_account_id = "your-databricks-account-id"
```

### 4. Deploy Infrastructure

Initialize Terraform:
```bash
cd infra
terraform init
```

Plan the deployment:
```bash
terraform plan -var-file="terraform.tfvars"
```

Apply the configuration:
```bash
terraform apply -var-file="terraform.tfvars"
```

## Environment-Specific Deployments

For different environments, use the appropriate variable files:

```bash
# Development
terraform apply -var-file="terraform.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

## Key Features

### Security
- Public endpoints with Azure AD authentication
- Managed Identity for secure storage access
- Key Vault integration for secrets management
- Storage account configured without access keys (Azure AD only)
- Diagnostic logging to Log Analytics

> **Production Note**: For enhanced security, add VNet injection, private endpoints, and Network Security Groups.

### Unity Catalog
- Dedicated metastore with ADLS Gen2 storage
- Automatic catalog and schema creation
- Access connector for secure storage access
- Admin user permissions configuration
- Cross-workspace catalog sharing support

### Monitoring
- Log Analytics workspace integration
- Diagnostic settings for audit logging
- Resource tagging for cost management

### High Availability
- Multi-zone cluster deployment
- Autoscaling cluster configuration
- Separate clusters for different workloads

## Outputs

After successful deployment, Terraform will output:
- Databricks workspace URL
- Unity Catalog metastore ID
- Resource group information
- Storage account details
- Cluster IDs

## Post-Deployment Steps

1. **Access Databricks Workspace**:
   - Use the workspace URL from Terraform outputs
   - Login with your Azure AD credentials

2. **Verify Unity Catalog**:
   - Check that Unity Catalog is enabled
   - Verify the metastore connection
   - Test catalog and schema creation

3. **Configure User Access**:
   - Add users to appropriate workspace groups
   - Configure Unity Catalog permissions
   - Set up data access policies

4. **Test Clusters**:
   - Start the Unity Catalog cluster
   - Verify Unity Catalog functionality
   - Test data access and permissions

## File Structure

```
infra/
├── main.tf              # Core Azure resources (Resource Group, Storage, Key Vault)
├── multi-workspace.tf   # Analytics workspace configuration
├── unity-catalog.tf     # Unity Catalog metastore and catalog setup
├── clusters.tf          # Databricks cluster definitions
├── security.tf          # Role assignments, diagnostics, Log Analytics
├── variables.tf         # Variable definitions
├── outputs.tf           # Output values (workspace URLs, etc.)
├── versions.tf          # Terraform and provider versions
├── terraform.tfvars     # Development variables
├── prod.tfvars          # Production variables
├── deploy.ps1           # PowerShell deployment script
└── deploy.sh            # Bash deployment script
```

## Troubleshooting

### Unity Catalog Issues
- Verify Databricks Account ID is correct
- Check that the storage account has proper permissions
- Ensure the access connector is properly configured

### Network Issues
- This deployment uses public endpoints by default
- Ensure your network allows outbound access to Azure Databricks control plane
- Check firewall rules if accessing from corporate networks
- For VNet-injected deployments, verify subnet delegation and NSG rules

### Permission Issues
- Verify Azure AD permissions for Terraform service principal
- Check Databricks workspace admin permissions
- Ensure proper role assignments are in place

## Cleanup

### Standard Destroy

To destroy all resources:
```bash
terraform destroy -var-file="terraform.tfvars"
```

**Warning**: This will delete all resources including data. Make sure to backup any important data before destroying.

### Unity Catalog Destroy Sequence (If Standard Destroy Fails)

Due to dependencies between Unity Catalog resources, a standard `terraform destroy` may fail with an error like:

> *"Storage credential cannot be deleted because it is configured as this metastore's root credential"*

This happens because the Databricks provider tries to delete the metastore data access (storage credential) before the metastore itself, but the metastore still references it as the root credential.

**Follow these steps in order:**

#### Step 1: Remove the metastore data access from Terraform state
```powershell
terraform state rm "databricks_metastore_data_access.unity_catalog[0]"
```

#### Step 2: Destroy the metastore (this will clean up its own root credential)
```powershell
terraform destroy -target="databricks_metastore.unity_catalog[0]" -auto-approve
```

#### Step 3: Destroy remaining resources
```powershell
terraform destroy -auto-approve
```

### Alternative: Destroy with Explicit Dependencies

If you prefer to handle this without state manipulation, you can also:

1. **First**, manually delete the metastore from the Databricks Account Console
2. **Then**, run `terraform destroy` to clean up remaining Azure resources

### Clean State After Failed Destroy

If a destroy partially fails, you may need to clean up the Terraform state:
```powershell
# List all resources in state
terraform state list

# Remove orphaned resources from state (example)
terraform state rm "resource_type.resource_name"

# Then destroy remaining resources
terraform destroy -auto-approve
```

## Cost Optimization

- Use autotermination for clusters to avoid idle costs
- Choose appropriate VM sizes based on workload requirements
- Monitor usage through Azure Cost Management
- Consider using Spot instances for non-critical workloads

## Security Best Practices

### Current Deployment (Development/Demo)
- Uses public endpoints for simplicity
- Azure AD authentication for storage (no access keys)
- Managed Identity for secure operations
- Diagnostic logging enabled

### Production Recommendations
- Add VNet injection with dedicated subnets
- Enable private endpoints for storage accounts
- Use Azure Private Link for Databricks workspace access
- Implement Network Security Groups with minimal required access
- Add IP-based access restrictions
- Regularly rotate keys and secrets
- Use Azure Policy for governance and compliance

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
