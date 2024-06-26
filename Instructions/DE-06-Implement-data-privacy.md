---
lab:
    title: 'Implementing Data Privacy and Governance using Microsoft Purview and Unity Catalog with Azure Databricks'
---

# Implementing Data Privacy and Governance using Microsoft Purview and Unity Catalog with Azure Databricks

## Objective
The objective of this lab is to demonstrate how to implement data privacy and governance using Microsoft Purview and Unity Catalog in Azure Databricks. By the end of this lab, you will be able to:

- Understand the integration between Microsoft Purview and Azure Databricks.
- Use Unity Catalog to manage and govern data assets.
- Implement data privacy and security policies.
- Monitor and audit data access and usage.

## Sample Dataset
We'll use a fictional e-commerce dataset containing customer information, sales transactions, and product details.

Customer Data: customers.csv
Columns: customer_id, name, email, phone, address, city, state, zip_code, country

Sales Data: sales.csv
Columns: sale_id, product_id, customer_id, quantity, price, sale_date

Product Data: products.csv
Columns: product_id, product_name, category, price, stock_quantity

## Prerequisites
- Azure Subscription
- Azure Databricks workspace
- Microsoft Purview account
- Basic knowledge of Azure Databricks and data governance concepts

## Step-by-Step Instructions
### Step 1: Set Up Azure Databricks and Unity Catalog
1. Create Azure Databricks Workspace

- Navigate to the Azure portal.
- Click on "Create a resource" and search for "Azure Databricks".
- Click "Create" and fill in the necessary details to create a Databricks workspace.

2. Create a Unity Catalog Metastore
- In the Azure Databricks workspace, navigate to the Unity Catalog section.
- Click "Create Metastore" and provide a name and associated storage account.

3. Assign the Unity Catalog Metastore to a Databricks Workspace
- Go to the Databricks workspace and select the workspace you created.
- Under the "Settings" tab, choose "Metastore" and select the Unity Catalog metastore you created.

### Step 2: Ingest Sample Data into Azure Databricks
1. Upload Sample Data to Databricks

- Use the Databricks interface to upload customers.csv, sales.csv, and products.csv to the DBFS (Databricks File System).

2. Create Tables from CSV Files

```python
# Load Customer Data
customers_df = spark.read.format("csv").option("header", "true").load("/dbfs/FileStore/customers.csv")
customers_df.write.saveAsTable("ecommerce.customers")

# Load Sales Data
sales_df = spark.read.format("csv").option("header", "true").load("/dbfs/FileStore/sales.csv")
sales_df.write.saveAsTable("ecommerce.sales")

# Load Product Data
products_df = spark.read.format("csv").option("header", "true").load("/dbfs/FileStore/products.csv")
products_df.write.saveAsTable("ecommerce.products")
```

### Step 3: Set Up Microsoft Purview

1. Create a Microsoft Purview Account

- Navigate to the Azure portal.
- Click on "Create a resource" and search for "Microsoft Purview".
- Click "Create" and fill in the necessary details to create a Purview account.

2. Connect Azure Databricks with Microsoft Purview

- In the Purview portal, navigate to the "Data Map" section.
- Click "Register" to register your Azure Databricks as a data source.
- Provide the necessary connection details and credentials.

### Step 4: Implement Data Privacy and Governance Policies
1. Create Classifications in Microsoft Purview

- In the Purview portal, go to the "Classifications" section.
- Create classifications such as "PII" (Personally Identifiable Information).

2. Apply Classifications to Data Assets
- Navigate to the "Data Catalog" in Purview.
- Locate the Databricks tables and apply the relevant classifications (e.g., classify the email and phone columns in the customers table as PII).

3. Set Up Data Policies in Unity Catalog

- Go to Unity Catalog in Databricks.
- Create a data access policy to restrict access to PII data.

```sql
CREATE OR REPLACE TABLE ecommerce.customers (
  customer_id STRING,
  name STRING,
  email STRING,
  phone STRING,
  address STRING,
  city STRING,
  state STRING,
  zip_code STRING,
  country STRING
) TBLPROPERTIES ('data_classification'='PII');

GRANT SELECT ON TABLE ecommerce.customers TO ROLE data_scientist;
REVOKE SELECT (email, phone) ON TABLE ecommerce.customers FROM ROLE data_scientist;
```

### Step 5: Monitor and Audit Data Access
1. Set Up Monitoring in Microsoft Purview

- In Purview, navigate to the "Insights" section.
- Set up monitoring to track data access and usage.

2. Audit Data Access in Databricks

- Use Databricks audit logs to monitor access to sensitive data.
- Enable diagnostic logging in Databricks and integrate with Azure Monitor for centralized logging and alerting.

### Step 6: Validate Data Privacy and Governance
1. Test Data Access Restrictions

- Attempt to query the customers table as a user with the data_scientist role.
- Verify that access to PII columns (email and phone) is restricted.

2. Review Audit Logs and Insights

- Check Purview insights for data access patterns.
- Review Databricks audit logs to ensure compliance with data privacy policies.

By following these steps, you have successfully implemented data privacy and governance using Microsoft Purview and Unity Catalog with Azure Databricks. This lab has equipped you with the knowledge to manage and govern data assets, enforce data privacy policies, and monitor data usage effectively.