# Unity Catalog Multi-Workspace Hands-On Labs

This lab series guides you through using two Azure Databricks workspaces with a shared Unity Catalog metastore to demonstrate cross-workspace data engineering and analytics capabilities.

## 🎯 **Lab Objectives**

By completing these labs, you will:
- Deploy multi-workspace Databricks infrastructure using Terraform
- Understand Unity Catalog's cross-workspace data sharing capabilities
- Perform data engineering activities in a primary workspace
- Access and analyze shared data from a secondary analytics workspace
- Experience centralized governance without data duplication

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                   Unity Catalog Metastore                    │
│              (Account-Level, Cross-Workspace)                │
└──────────────────────┬──────────────────────┬────────────────┘
                       │                      │
           ┌───────────▼─────────┐  ┌────────▼────────────┐
           │  PRIMARY WORKSPACE  │  │ ANALYTICS WORKSPACE │
           │  (Data Engineering) │  │  (Data Science/ML)  │
           │                     │  │                     │
           │  LAB 2: Create      │  │  LAB 3: Query &     │
           │  Delta Tables       │  │  Analyze Data       │
           └─────────────────────┘  └─────────────────────┘
                       │                      │
                       │  Shared Catalog      │
                       └──────────┬───────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │  shared_data.samples.*    │
                    │  - customers              │
                    │  - products               │
                    │  - transactions           │
                    └───────────────────────────┘
```

## 📚 **Lab Structure**

| Lab | Title | Duration | Focus |
|-----|-------|----------|-------|
| **Lab 1** | Infrastructure Deployment | 30-45 min | Deploy Terraform infrastructure |
| **Lab 2** | Data Engineering (Workspace 1) | 30-45 min | Create datasets in Unity Catalog |
| **Lab 3** | Analytics & Sharing (Workspace 2) | 30-45 min | Cross-workspace data access |

## 📋 **Prerequisites**

### **Required Tools**
- Azure CLI (authenticated to your subscription)
- Terraform >= 1.0
- Azure subscription with Contributor permissions
- Databricks account with Unity Catalog enabled

### **Required Permissions**
- Ability to create Resource Groups in Azure
- Databricks Account Admin (for Unity Catalog setup)
- Azure AD permissions for service principals (if applicable)

## 🚀 **Quick Start**

```powershell
# 1. Clone the repository
git clone <repository-url>
cd adb-iac

# 2. Start with Lab 1 to deploy infrastructure
cd labs/lab-01-infrastructure

# 3. Follow the step-by-step guide
```

## 🎓 **Learning Path**

### **Recommended Flow**

1. **Lab 1: Infrastructure Deployment**
   - Deploy both Databricks workspaces
   - Set up Unity Catalog metastore
   - Configure networking and storage

2. **Lab 2: Data Engineering**
   - Connect to the Primary workspace
   - Create sample Delta tables
   - Write data to Unity Catalog

3. **Lab 3: Analytics & Cross-Workspace Access**
   - Connect to the Analytics workspace
   - Access data created in Lab 2 (no data copy!)
   - Perform analytics and create derived tables

## 📖 **Key Concepts Covered**

### **Unity Catalog**
- Three-level namespace: `catalog.schema.table`
- Cross-workspace data sharing
- Centralized permissions and governance
- Data lineage and discovery

### **Delta Lake**
- ACID transactions
- Schema enforcement
- Time travel and versioning
- Partitioning strategies

### **Multi-Workspace Architecture**
- Workspace isolation for different teams
- Shared governance with Unity Catalog
- Zero data duplication across workspaces

## 📞 **Troubleshooting**

Common issues and solutions are documented in each lab. For additional help:
- Check the [DEMO-GUIDE.md](../src/notebooks/DEMO-GUIDE.md) for detailed workflows
- Review the [SOLUTION-OVERVIEW.md](../SOLUTION-OVERVIEW.md) for architecture details
- Ensure your Azure subscription has the required quotas

## ✅ **Success Criteria**

After completing all labs, you should be able to:
- Explain the benefits of Unity Catalog for multi-workspace environments
- Deploy Databricks infrastructure using Terraform
- Create and manage Delta tables in Unity Catalog
- Access shared data from different workspaces
- Demonstrate data governance without data duplication
