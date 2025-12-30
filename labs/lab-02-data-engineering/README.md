# Lab 2: Data Engineering (Primary Workspace)

**Estimated Time**: 30-45 minutes  
**Difficulty**: Beginner-Intermediate  
**Prerequisites**: Completed Lab 1

## 🎯 **Lab Objectives**

In this lab, you will:
- Connect to the Primary (Data Engineering) workspace
- Create sample datasets using PySpark
- Write Delta tables to Unity Catalog's shared catalog
- Create views for cross-workspace data sharing
- Verify data is stored in the shared metastore

## 📋 **Prerequisites Checklist**

- [ ] Lab 1 completed successfully
- [ ] Primary workspace URL saved from Terraform outputs
- [ ] Azure AD credentials to access the workspace
- [ ] Basic familiarity with Databricks notebooks

---

## 🏗️ **Step 1: Access the Primary Workspace**

### **1.1 Get the Workspace URL**

From your Terraform deployment (Lab 1):

```powershell
cd adb-iac/infra
terraform output databricks_workspace_url
```

### **1.2 Open the Workspace**

1. Copy the workspace URL
2. Open it in your browser
3. Sign in with your Azure AD credentials
4. You should see the Databricks workspace home page

### **1.3 Verify Unity Catalog Access**

1. Click **Catalog** in the left sidebar
2. Verify you can see the `shared_data` catalog
3. Expand it to see the `samples` schema

---

## 📓 **Step 2: Import the Data Ingestion Notebook**

### **2.1 Locate the Notebook**

The notebook is located at:
```
adb-iac/src/notebooks/01-data-ingestion-primary-workspace.ipynb
```

### **2.2 Import to Workspace**

1. In the workspace, click **Workspace** in the left sidebar
2. Navigate to your user folder: **Users → your-email@company.com**
3. Click the **⋮** menu → **Import**
4. Select **File** and upload `01-data-ingestion-primary-workspace.ipynb`
5. Click **Import**

### **2.3 Open the Notebook**

Click on the imported notebook to open it.

---

## 🔧 **Step 3: Attach a Cluster**

### **3.1 Start a Cluster**

1. In the notebook, click **Connect** at the top right
2. Select one of the available clusters:
   - **Unity Catalog Cluster** (recommended)
   - **Shared Cluster**
3. If the cluster is stopped, click **Start**
4. Wait for the cluster to be running (2-5 minutes)

### **3.2 Verify Cluster Configuration**

The cluster should have:
- Unity Catalog enabled
- Access mode: Single user or Shared
- Runtime: DBR 13.0+ with Unity Catalog support

---

## 📊 **Step 4: Run the Data Ingestion Notebook**

### **4.1 Notebook Overview**

The notebook performs these tasks:

| Section | Description |
|---------|-------------|
| Setup | Import libraries, verify Spark version |
| Unity Catalog Check | Verify catalog access, list available catalogs |
| Customer Data | Create 10 sample customer records |
| Product Data | Create 10 sample product records |
| Transaction Data | Create 12 sample transaction records |
| Verification | List and describe created tables |
| View Creation | Create a view joining customer and transaction data |

### **4.2 Run All Cells**

Option 1: **Run cell by cell**
- Click each cell and press `Shift + Enter`
- Review the output of each cell

Option 2: **Run all cells**
- Click **Run All** from the notebook menu
- Monitor progress in each cell

### **4.3 Expected Outputs**

After running the notebook, you should see:

**Cell: Verify Unity Catalog Configuration**
```
Current Catalog: shared_data
Available Catalogs:
┌─────────────┐
│ catalog     │
├─────────────┤
│ shared_data │
│ system      │
└─────────────┘
```

**Cell: Customer Data Creation**
```
Created 10 customer records
┌─────────────┬────────────────┬──────────────┬─────────┬─────────────┬──────────────────┬────────────────┐
│ customer_id │ customer_name  │ email        │ country │ signup_date │ total_purchases  │ lifetime_value │
├─────────────┼────────────────┼──────────────┼─────────┼─────────────┼──────────────────┼────────────────┤
│ 1           │ Alice Johnson  │ alice@...    │ USA     │ 2023-01-15  │ 45               │ 12500.50       │
│ ...         │ ...            │ ...          │ ...     │ ...         │ ...              │ ...            │
└─────────────┴────────────────┴──────────────┴─────────┴─────────────┴──────────────────┴────────────────┘
```

**Cell: Write to Delta Table**
```
✅ Successfully created Delta table: shared_data.samples.customers
```

---

## ✅ **Step 5: Verify the Created Tables**

### **5.1 Using the Notebook**

Run the verification cell in the notebook:

```python
# List all tables in the schema
print("Tables in shared_data.samples schema:")
display(spark.sql("SHOW TABLES IN shared_data.samples"))
```

Expected output:
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

### **5.2 Using the Catalog Explorer**

1. Click **Catalog** in the left sidebar
2. Navigate to: `shared_data` → `samples`
3. You should see:
   - `customers` (table)
   - `products` (table)
   - `transactions` (table)
   - `customer_transactions` (view)

### **5.3 Inspect Table Details**

Click on any table to see:
- **Schema** - Column names and data types
- **Sample Data** - Preview of table contents
- **Details** - Owner, created date, location
- **History** - Delta Lake version history

---

## 📝 **Step 6: Understand What You Created**

### **Data Model**

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    customers    │     │  transactions   │     │    products     │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ customer_id  PK │◄────┤ customer_id  FK │     │ product_id   PK │
│ customer_name   │     │ transaction_id  │     │ product_name    │
│ email           │     │ product_id   FK │────►│ category        │
│ country         │     │ quantity        │     │ price           │
│ signup_date     │     │ total_amount    │     │ stock_quantity  │
│ total_purchases │     │ transaction_date│     │ supplier        │
│ lifetime_value  │     │ payment_method  │     └─────────────────┘
└─────────────────┘     └─────────────────┘
```

### **Tables Summary**

| Table | Records | Partition | Purpose |
|-------|---------|-----------|---------|
| `customers` | 10 | None | Customer master data |
| `products` | 10 | None | Product catalog |
| `transactions` | 12 | `transaction_date` | Sales transactions |

### **View Created**

The `customer_transactions` view joins customers and transactions:
```sql
-- View definition
SELECT 
    c.customer_id,
    c.customer_name,
    c.country,
    t.transaction_id,
    t.total_amount,
    t.transaction_date,
    t.payment_method
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
```

---

## 🔧 **Troubleshooting**

### **Issue: Cannot see shared_data catalog**

```sql
-- Check available catalogs
SHOW CATALOGS;

-- If shared_data is missing, check metastore attachment
-- This should have been set up in Lab 1
```

**Solution**: Verify Unity Catalog metastore is attached in Lab 1 Terraform outputs.

### **Issue: Permission denied writing tables**

```sql
-- Check your permissions on the catalog
SHOW GRANTS ON CATALOG shared_data;

-- Check schema permissions
SHOW GRANTS ON SCHEMA shared_data.samples;
```

**Solution**: Ensure you have USAGE and CREATE permissions on the catalog and schema.

### **Issue: Cluster fails to start**

1. Check cluster configuration for Unity Catalog support
2. Verify your user has access to the cluster
3. Check Azure resource quotas

### **Issue: Delta table write fails**

```python
# Check if table already exists
spark.sql("SHOW TABLES IN shared_data.samples").show()

# Drop and recreate if needed
spark.sql("DROP TABLE IF EXISTS shared_data.samples.customers")
```

---

## 🎓 **Key Learnings**

### **Unity Catalog Namespace**

```
catalog.schema.table
   │       │      │
   │       │      └── Table name
   │       └── Schema (database) name  
   └── Catalog name
```

Example: `shared_data.samples.customers`

### **Delta Lake Features Used**

- **ACID Transactions**: Guaranteed data consistency
- **Schema Enforcement**: Automatic validation
- **Partitioning**: `transactions` partitioned by date
- **Overwrite Mode**: Replace existing data

### **Cross-Workspace Preparation**

The data you created is now:
- Stored in Unity Catalog metastore
- Accessible from ANY workspace attached to the same metastore
- Governed by centralized permissions
- **No data duplication required** for access from other workspaces

---

## ➡️ **Next Steps**

**Congratulations!** You've completed the data engineering workflow.

**Proceed to [Lab 3: Analytics & Cross-Workspace Access](../lab-03-analytics/README.md)** to:
- Connect to the Analytics workspace
- Access the data you just created (from a different workspace!)
- Perform analytics and create derived datasets

---

## 📚 **Additional Resources**

- [Unity Catalog Documentation](https://docs.databricks.com/data-governance/unity-catalog/index.html)
- [Delta Lake Guide](https://docs.databricks.com/delta/index.html)
- [Databricks SQL Best Practices](https://docs.databricks.com/sql/best-practices.html)
