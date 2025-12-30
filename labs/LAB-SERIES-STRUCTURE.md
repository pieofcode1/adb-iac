# Lab Series Structure

## 📚 **Overview**

This lab series focuses on demonstrating Azure Databricks multi-workspace architecture with Unity Catalog for cross-workspace data sharing. The labs guide users through deploying infrastructure, performing data engineering, and accessing shared data from different workspaces.

## 🎯 **Lab Series Goals**

1. Deploy a multi-workspace Databricks environment
2. Create datasets in a data engineering workspace
3. Access and analyze data from an analytics workspace
4. Demonstrate Unity Catalog's cross-workspace capabilities

---

## **Lab 1: Infrastructure Deployment** ✅

**Duration**: 30-45 minutes  
**Difficulty**: Intermediate

### **Objectives**
- Deploy Azure infrastructure using Terraform
- Create two Databricks workspaces (Primary & Analytics)
- Set up Unity Catalog metastore
- Configure shared storage and resources

### **Key Activities**
1. Review and configure `terraform.tfvars`
2. Run `terraform init` and `terraform apply`
3. Verify workspace creation in Azure portal
4. Note workspace URLs from Terraform outputs

### **Resources Created**
- Resource Group
- 2 Databricks Workspaces (public endpoints)
- Unity Catalog Metastore
- ADLS Gen2 Storage Account
- Key Vault
- Managed Identity
- Log Analytics Workspace

---

## **Lab 2: Data Engineering (Primary Workspace)** ✅

**Duration**: 30-45 minutes  
**Difficulty**: Beginner-Intermediate

### **Objectives**
- Connect to the Primary (Data Engineering) workspace
- Create sample datasets using PySpark
- Write Delta tables to Unity Catalog
- Verify data in the shared catalog

### **Key Activities**
1. Access Primary workspace URL
2. Import and run `01-data-ingestion-primary-workspace.ipynb`
3. Create customer, product, and transaction tables
4. Create views for cross-workspace access

### **Tables Created**
| Table | Description | Records |
|-------|-------------|---------|
| `shared_data.samples.customers` | Customer profiles | 10 |
| `shared_data.samples.products` | Product catalog | 10 |
| `shared_data.samples.transactions` | Sales transactions | 12 |

### **Key Concepts**
- Unity Catalog three-level namespace
- Delta Lake table creation
- Partitioning strategies
- View creation for lineage

---

## **Lab 3: Analytics & Cross-Workspace Access** ✅

**Duration**: 30-45 minutes  
**Difficulty**: Beginner-Intermediate

### **Objectives**
- Connect to the Analytics workspace
- Access data created in Lab 2 (without data duplication)
- Perform analytics and create derived datasets
- Demonstrate governance and permissions

### **Key Activities**
1. Access Analytics workspace URL
2. Import and run `02-cross-workspace-access-analytics.ipynb`
3. Query shared tables from different workspace
4. Create analytics summaries and ML features
5. Explore data lineage

### **Key Demonstrations**
- Zero data duplication between workspaces
- Instant cross-workspace data access
- Consistent security and governance
- Full analytics capabilities on shared data

### **Analytics Performed**
- Customer segmentation by country
- Revenue analysis by product category
- Payment method distribution
- Customer lifetime value analysis
- RFM (Recency, Frequency, Monetary) scoring

---

## 📊 **Complete Lab Flow**

```
┌─────────────────────────────────────────────────────────────────┐
│                         LAB 1                                    │
│                Infrastructure Deployment                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Terraform    │→ │ 2 Workspaces │→ │ Unity Catalog        │   │
│  │ Apply        │  │ Created      │  │ Metastore Setup      │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         LAB 2                                    │
│              Data Engineering (Primary Workspace)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Create       │→ │ Write Delta  │→ │ Tables in            │   │
│  │ DataFrames   │  │ Tables       │  │ shared_data.samples  │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         LAB 3                                    │
│            Analytics (Analytics Workspace)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Access       │→ │ Query &      │→ │ Create Analytics     │   │
│  │ Shared Data  │  │ Analyze      │  │ Summaries            │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ **Lab Materials**

### **Notebooks**
| Notebook | Lab | Location |
|----------|-----|----------|
| Data Ingestion | Lab 2 | `src/notebooks/01-data-ingestion-primary-workspace.ipynb` |
| Cross-Workspace Analytics | Lab 3 | `src/notebooks/02-cross-workspace-access-analytics.ipynb` |

### **Infrastructure Code**
| File | Purpose |
|------|---------|
| `infra/main.tf` | Core Azure resources |
| `infra/multi-workspace.tf` | Analytics workspace configuration |
| `infra/unity-catalog.tf` | Unity Catalog setup |
| `infra/clusters.tf` | Databricks cluster configuration |

### **Documentation**
| Document | Purpose |
|----------|---------|
| `SOLUTION-OVERVIEW.md` | Complete solution architecture |
| `src/notebooks/DEMO-GUIDE.md` | Step-by-step demo workflow |
| `DEPLOYMENT-CHECKLIST.md` | Deployment verification steps |

---

## ✅ **Validation Checkpoints**

### **After Lab 1**
- [ ] Both workspaces accessible in Azure portal
- [ ] Unity Catalog metastore created and attached
- [ ] Terraform outputs show workspace URLs
- [ ] Clusters are created (may be stopped)

### **After Lab 2**
- [ ] 3 Delta tables created in `shared_data.samples`
- [ ] View `customer_transactions` created
- [ ] Data visible in Databricks Catalog Explorer

### **After Lab 3**
- [ ] Successfully queried tables from Analytics workspace
- [ ] Analytics tables created (e.g., `customer_summary`)
- [ ] Verified same data accessible without duplication
