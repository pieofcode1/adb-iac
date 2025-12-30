# Lab 3: Analytics & Cross-Workspace Access

**Estimated Time**: 30-45 minutes  
**Difficulty**: Beginner-Intermediate  
**Prerequisites**: Completed Lab 1 and Lab 2

## 🎯 **Lab Objectives**

In this lab, you will:
- Connect to the Analytics workspace (different from the Primary workspace)
- Access data created in Lab 2 **without any data duplication**
- Perform analytics queries on shared data
- Create derived datasets and analytics summaries
- Experience the power of Unity Catalog's cross-workspace data sharing

## 📋 **Prerequisites Checklist**

- [ ] Lab 1 completed (infrastructure deployed)
- [ ] Lab 2 completed (data created in Primary workspace)
- [ ] Analytics workspace URL saved from Terraform outputs
- [ ] Tables exist in `shared_data.samples` schema

---

## 🎯 **The Key Concept**

### **What Makes This Lab Special**

```
┌─────────────────────────────────────────────────────────────┐
│                                                              │
│  In Lab 2, you created data in the PRIMARY workspace        │
│                                                              │
│  In Lab 3, you will access that SAME data from the          │
│  ANALYTICS workspace - WITHOUT copying or moving it!        │
│                                                              │
│  This is the power of Unity Catalog:                        │
│  ✓ Zero data duplication                                    │
│  ✓ Instant cross-workspace access                           │
│  ✓ Centralized governance                                   │
│  ✓ Consistent permissions                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ **Step 1: Access the Analytics Workspace**

### **1.1 Get the Analytics Workspace URL**

From your Terraform deployment (Lab 1):

```powershell
cd adb-iac/infra
terraform output analytics_workspace_url
```

### **1.2 Open the Analytics Workspace**

1. Copy the **Analytics** workspace URL (different from Primary!)
2. Open it in your browser
3. Sign in with your Azure AD credentials
4. Verify you're in the **Analytics** workspace (check the URL/workspace name)

### **1.3 Verify This is a Different Workspace**

**Important**: Confirm you're NOT in the Primary workspace:
- The workspace URL should be different
- The workspace name should include "analytics"

### **1.4 Verify Unity Catalog Access**

1. Click **Catalog** in the left sidebar
2. You should see the **same** `shared_data` catalog from Lab 2!
3. Expand it to see the `samples` schema with your tables

🎉 **This is the magic**: Same catalog, different workspace, no data copy!

---

## 📓 **Step 2: Import the Analytics Notebook**

### **2.1 Locate the Notebook**

The notebook is located at:
```
adb-iac/src/notebooks/02-cross-workspace-access-analytics.ipynb
```

### **2.2 Import to Analytics Workspace**

1. In the **Analytics** workspace, click **Workspace** in the left sidebar
2. Navigate to your user folder: **Users → your-email@company.com**
3. Click the **⋮** menu → **Import**
4. Select **File** and upload `02-cross-workspace-access-analytics.ipynb`
5. Click **Import**

### **2.3 Open the Notebook**

Click on the imported notebook to open it.

---

## 🔧 **Step 3: Attach a Cluster**

### **3.1 Start the Analytics Cluster**

1. In the notebook, click **Connect** at the top right
2. Select **Analytics Cluster**
3. If the cluster is stopped, click **Start**
4. Wait for the cluster to be running (2-5 minutes)

---

## 📊 **Step 4: Run the Analytics Notebook**

### **4.1 Notebook Overview**

The notebook demonstrates:

| Section | Description |
|---------|-------------|
| Workspace Verification | Confirm you're in the Analytics workspace |
| Catalog Access | Access `shared_data` catalog (same as Primary!) |
| Data Exploration | Browse tables created in Lab 2 |
| Customer Analysis | Aggregate customer data by country |
| Cross-Table Analysis | Join customers, products, transactions |
| Revenue Analytics | Analyze revenue by category and payment method |
| Create Derived Data | Build analytics summaries |

### **4.2 Run Key Cells**

#### **Cell: Verify Workspace**

```python
# Check workspace information
workspace_url = spark.conf.get("spark.databricks.workspaceUrl")
print(f"Current Workspace: {workspace_url}")
print(f"This is the ANALYTICS workspace\n")
```

**Expected Output:**
```
Current Workspace: adb-xxxxxxx.xx.azuredatabricks.net
This is the ANALYTICS workspace
```

#### **Cell: Access Shared Catalog**

```python
# Switch to shared catalog
spark.sql("USE CATALOG shared_data")
spark.sql("USE SCHEMA samples")

print("✅ Connected to shared_data.samples")
print("   This catalog was created in the PRIMARY workspace")
print("   But is accessible here via Unity Catalog!")
```

#### **Cell: Query Tables from Lab 2**

```python
# List tables in the shared schema
print("Tables available in shared_data.samples:")
display(spark.sql("SHOW TABLES IN shared_data.samples"))
```

**Expected Output:**
```
┌──────────────┬─────────────────────┬───────────────┐
│ database     │ tableName           │ isTemporary   │
├──────────────┼─────────────────────┼───────────────┤
│ samples      │ customers           │ false         │
│ samples      │ products            │ false         │
│ samples      │ transactions        │ false         │
│ samples      │ customer_transactions│ false        │
└──────────────┴─────────────────────┴───────────────┘
```

🎉 **These are the same tables created in Lab 2!** No copying needed.

### **4.3 Run Analytics Queries**

#### **Customer Analysis**

```python
# Customer distribution by country
customers_df = spark.table("shared_data.samples.customers")

display(
    customers_df
    .groupBy("country")
    .agg(
        count("*").alias("customer_count"),
        sum("lifetime_value").alias("total_lifetime_value")
    )
    .orderBy(desc("total_lifetime_value"))
)
```

#### **Cross-Table Analysis**

```python
# Join customers, transactions, and products
customers = spark.table("shared_data.samples.customers")
transactions = spark.table("shared_data.samples.transactions")
products = spark.table("shared_data.samples.products")

# Comprehensive transaction analysis
transaction_analysis = (
    transactions
    .join(customers, "customer_id")
    .join(products, "product_id")
    .select("customer_name", "product_name", "category", "total_amount")
)

display(transaction_analysis)
```

### **4.4 Create Analytics Summaries**

The notebook creates a new table in the shared catalog:

```python
# Create customer summary table
spark.sql("""
CREATE OR REPLACE TABLE shared_data.samples.customer_summary AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.country,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.total_amount) as total_spent,
    AVG(t.total_amount) as avg_transaction_value
FROM shared_data.samples.customers c
LEFT JOIN shared_data.samples.transactions t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.customer_name, c.country
""")

print("✅ Created analytics table: shared_data.samples.customer_summary")
```

---

## ✅ **Step 5: Verify Cross-Workspace Access**

### **5.1 Confirm Data Origin**

The data you just queried was:
- ✅ Created in the **Primary** workspace (Lab 2)
- ✅ Queried from the **Analytics** workspace (Lab 3)
- ✅ **No data was copied** between workspaces
- ✅ Same permissions and governance apply

### **5.2 Check Table Metadata**

```sql
-- View table details
DESCRIBE EXTENDED shared_data.samples.customers;
```

Note the `Location` field - it points to the same storage regardless of which workspace you query from.

### **5.3 Verify New Analytics Table**

Go back to the **Primary** workspace and check:

1. Open Primary workspace
2. Navigate to **Catalog** → `shared_data` → `samples`
3. You should see `customer_summary` table (created in Analytics workspace!)

**This proves bi-directional sharing**: Both workspaces can read AND write to the shared catalog.

---

## 🎓 **Key Learnings**

### **Unity Catalog Benefits Demonstrated**

| Benefit | How It Was Shown |
|---------|------------------|
| **Zero Data Duplication** | Same tables accessed from 2 workspaces |
| **Instant Access** | No ETL, no data movement needed |
| **Centralized Governance** | Single catalog for multiple workspaces |
| **Consistent Security** | Same permissions in both workspaces |
| **Data Lineage** | Track who created/modified data |

### **Architecture Recap**

```
                    ┌───────────────────┐
                    │  Unity Catalog    │
                    │    Metastore      │
                    └─────────┬─────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
     ┌────────▼───────┐      │      ┌────────▼───────┐
     │    Primary     │      │      │   Analytics    │
     │   Workspace    │      │      │   Workspace    │
     │                │      │      │                │
     │  Lab 2: Write  │      │      │  Lab 3: Read   │
     │  - customers   │◄─────┼─────►│  - Query all   │
     │  - products    │      │      │  - Analytics   │
     │  - transactions│      │      │  - customer_   │
     └────────────────┘      │      │    summary     │
                              │      └────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   shared_data     │
                    │    .samples.*     │
                    │  (ADLS Gen2)      │
                    └───────────────────┘
```

### **When to Use This Pattern**

- **Data Engineering Team**: Creates and curates data in one workspace
- **Data Science Team**: Analyzes data in a separate workspace with different tools
- **BI Team**: Accesses data via SQL Warehouse
- **All teams**: Share the same governed data without copies

---

## 🔧 **Troubleshooting**

### **Issue: Cannot see shared_data catalog**

Verify both workspaces are attached to the same metastore:

```sql
-- Check current metastore
SELECT current_metastore();
```

### **Issue: Permission denied on tables**

```sql
-- Check your permissions
SHOW GRANTS ON TABLE shared_data.samples.customers;
```

### **Issue: Tables show 0 records**

Verify Lab 2 was completed successfully:
1. Go back to Primary workspace
2. Query the tables to confirm data exists
3. Re-run Lab 2 notebook if needed

---

## 🎉 **Congratulations!**

You've successfully completed the lab series and demonstrated:

✅ **Lab 1**: Deployed multi-workspace infrastructure with Terraform  
✅ **Lab 2**: Created Delta tables in Unity Catalog (Primary workspace)  
✅ **Lab 3**: Accessed and analyzed shared data (Analytics workspace)

### **Key Takeaways**

1. **Unity Catalog** enables cross-workspace data sharing without data duplication
2. **Delta Lake** provides ACID transactions and versioning
3. **Terraform** makes multi-workspace deployments reproducible
4. **Centralized Governance** ensures consistent security across all workspaces

---

## 🧹 **Cleanup**

When you're finished with all labs, clean up resources:

```powershell
cd adb-iac/infra
terraform destroy -var-file="terraform.tfvars"
```

⚠️ **Warning**: This will delete all resources including the data you created.

---

## 📚 **Additional Resources**

- [Unity Catalog Best Practices](https://docs.databricks.com/data-governance/unity-catalog/best-practices.html)
- [Cross-Workspace Data Sharing](https://docs.databricks.com/data-governance/unity-catalog/manage-privileges/index.html)
- [Delta Lake Documentation](https://docs.delta.io/)
- [Databricks ML on Unity Catalog](https://docs.databricks.com/machine-learning/index.html)

---

## 🚀 **What's Next?**

Now that you understand the basics, try these advanced scenarios:

1. **Add more tables** in the Primary workspace and query from Analytics
2. **Set up granular permissions** using Unity Catalog grants
3. **Create ML features** in the Analytics workspace
4. **Set up a SQL Warehouse** for BI tool connectivity
5. **Implement data lineage tracking** for compliance
