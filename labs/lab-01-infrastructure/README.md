# Lab 1: Infrastructure Deployment

**Estimated Time**: 30-45 minutes  
**Difficulty**: Intermediate  
**Prerequisites**: Azure CLI authenticated, Terraform installed

## 🎯 **Lab Objectives**

In this lab, you will:
- Deploy Azure infrastructure for two Databricks workspaces using Terraform
- Set up Unity Catalog metastore shared between both workspaces
- Configure networking, storage, and supporting resources
- Verify the deployment and note workspace URLs

## 📋 **Prerequisites Checklist**

### **Tools Required**
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform >= 1.0 installed
- [ ] PowerShell or Bash terminal
- [ ] Git (for cloning the repository)

### **Azure Requirements**
- [ ] Active Azure subscription
- [ ] Contributor or Owner permissions on subscription
- [ ] Databricks Account Admin access (for Unity Catalog)
- [ ] Sufficient quota for Databricks workspaces (2 required)

### **Verify Your Setup**

```powershell
# Check Azure CLI
az version
az account show

# Check Terraform
terraform version
```

---

## 🏗️ **Step 1: Review the Infrastructure**

### **1.1 Navigate to Infrastructure Directory**

```powershell
cd adb-iac/infra
```

### **1.2 Understand the Terraform Files**

| File | Purpose |
|------|---------|
| `main.tf` | Core Azure resources (Resource Group, VNet, Storage) |
| `multi-workspace.tf` | Analytics workspace configuration |
| `unity-catalog.tf` | Unity Catalog metastore and catalog setup |
| `clusters.tf` | Databricks cluster definitions |
| `security.tf` | Key Vault and security resources |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Output values (workspace URLs, etc.) |

### **1.3 Review Key Resources**

The Terraform configuration creates:

**Azure Resources:**
- Resource Group
- Storage Account (ADLS Gen2) for Unity Catalog
- Key Vault for secrets
- Managed Identity
- Log Analytics Workspace

**Databricks Resources:**
- **Primary Workspace** - For data engineering activities (public endpoint)
- **Analytics Workspace** - For data science and analytics (public endpoint)
- Unity Catalog Metastore (shared between workspaces)
- Databricks Clusters (Unity Catalog enabled)

> **Note**: This deployment uses public endpoints for simplicity. VNet injection can be added for production environments.

---

## ⚙️ **Step 2: Configure Variables**

### **2.1 Create Your Configuration File**

```powershell
# Copy the sample configuration
cp terraform.tfvars.sample terraform.tfvars
```

### **2.2 Edit terraform.tfvars**

Open `terraform.tfvars` and configure:

```hcl
# Required: Your Azure region
location = "East US"

# Required: Environment name (used in resource naming)
environment = "dev"

# Required: Your email for resource tagging
owner_email = "your-email@company.com"

# Optional: Resource prefix
resource_prefix = "adb"

# Required: Databricks Account ID (for Unity Catalog)
# Find this in the Databricks Account Console
databricks_account_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### **2.3 Find Your Databricks Account ID**

1. Go to [accounts.azuredatabricks.net](https://accounts.azuredatabricks.net)
2. Sign in with your Azure AD credentials
3. Your Account ID is shown in the URL or Account Settings

---

## 🚀 **Step 3: Deploy the Infrastructure**

### **3.1 Initialize Terraform**

```powershell
terraform init
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### **3.2 Preview the Changes**

```powershell
terraform plan -var-file="terraform.tfvars"
```

Review the plan and verify:
- 2 Databricks workspaces will be created
- Unity Catalog metastore will be set up
- Networking and storage resources are correct

### **3.3 Apply the Configuration**

```powershell
terraform apply -var-file="terraform.tfvars"
```

When prompted, type `yes` to confirm.

**⏱️ Deployment Time**: Approximately 15-25 minutes

### **3.4 Note the Outputs**

After deployment completes, save these values:

```powershell
# Get all outputs
terraform output

# Or get specific outputs
terraform output databricks_workspace_url      # Primary workspace
terraform output analytics_workspace_url       # Analytics workspace
terraform output unity_catalog_metastore_id   # Metastore ID
```

**Save these URLs!** You'll need them for Labs 2 and 3.

---

## ✅ **Step 4: Verify the Deployment**

### **4.1 Azure Portal Verification**

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to your Resource Group
3. Verify these resources exist:
   - [ ] 2 Databricks Workspaces
   - [ ] Virtual Network
   - [ ] Storage Account
   - [ ] Key Vault
   - [ ] Managed Identity

### **4.2 Primary Workspace Verification**

1. Open the Primary workspace URL
2. Navigate to **Catalog** in the left sidebar
3. Verify:
   - [ ] `shared_data` catalog exists
   - [ ] `samples` schema exists in the catalog
   - [ ] Unity Catalog is enabled

### **4.3 Analytics Workspace Verification**

1. Open the Analytics workspace URL
2. Navigate to **Catalog** in the left sidebar
3. Verify:
   - [ ] `shared_data` catalog is visible
   - [ ] Same metastore as Primary workspace

### **4.4 Verify Clusters**

In the Primary workspace:
1. Go to **Compute** → **All-purpose compute**
2. Verify clusters exist (they may be stopped to save costs)

---

## 🔧 **Troubleshooting**

### **Common Issues**

#### **Issue: Terraform init fails**
```powershell
# Clear cache and retry
Remove-Item -Recurse -Force .terraform
terraform init
```

#### **Issue: Insufficient permissions**
```powershell
# Verify your Azure role
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)
```

#### **Issue: Databricks account ID not found**
- Ensure you're using an Azure AD account with Databricks access
- Verify at [accounts.azuredatabricks.net](https://accounts.azuredatabricks.net)

#### **Issue: Unity Catalog not showing in workspace**
- Wait 5-10 minutes for metastore attachment to propagate
- Refresh the workspace browser
- Check metastore assignment in Terraform outputs

### **Resource Quotas**

If you hit quota limits:
```powershell
# Check current usage
az vm list-usage --location "East US" --output table
```

---

## 📊 **What You've Built**

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────┐         ┌────────────────┐             │
│  │   Primary      │         │   Analytics    │             │
│  │   Workspace    │         │   Workspace    │             │
│  │                │         │                │             │
│  │ (Data Eng)     │         │ (Data Science) │             │
│  └───────┬────────┘         └───────┬────────┘             │
│          │                          │                       │
│          └──────────┬───────────────┘                       │
│                     │                                        │
│          ┌──────────▼──────────┐                            │
│          │  Unity Catalog      │                            │
│          │  Metastore          │                            │
│          │  (Shared)           │                            │
│          └─────────────────────┘                            │
│                     │                                        │
│          ┌──────────▼──────────┐                            │
│          │  ADLS Gen2          │                            │
│          │  Storage            │                            │
│          └─────────────────────┘                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## ➡️ **Next Steps**

**Congratulations!** You've deployed the multi-workspace infrastructure.

**Proceed to [Lab 2: Data Engineering](../lab-02-data-engineering/README.md)** to:
- Connect to the Primary workspace
- Create sample Delta tables
- Write data to Unity Catalog

---

## 🧹 **Cleanup (Optional)**

To destroy all resources when done with all labs:

```powershell
terraform destroy -var-file="terraform.tfvars"
```

⚠️ **Warning**: This will delete all data and resources. Only run this when you're completely finished with all labs.
