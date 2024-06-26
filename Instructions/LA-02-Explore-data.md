---
lab:
    title: 'Explore data with Azure Databricks'
---

# Explore data with Azure Databricks
## Objective
Learn to load, explore, and perform analysis on a sample retail dataset using Azure Databricks.

## Prerequisites
- An active Azure subscription. If you do not have one, you can sign up for a [free trial](https://azure.microsoft.com/en-us/free/).
- Access to an Azure Databricks workspace.
- Basic knowledge of Python and SQL.

## Estimated time: 120 minutes

## Lab Setup

### Create a Databricks Cluster
- Log into your Azure Databricks workspace.
- Navigate to the “Clusters” section and create a new cluster.
- Choose the latest Databricks Runtime version and ensure Python 3 is selected.
    
### Create a Notebook
- In the workspace, create a new notebook.
- Set Python as the default language for the notebook.

#### Step 1: Loading the Data
- Navigate to "Data" in the sidebar, click "Add Data", and upload the [Retail data by day](../../Allfiles/Labs/02/retail-data/by-day/*.csv).

##### Read the Dataset

```python
retail_df = spark.read.format("csv").option("header", "true").option("inferSchema", "true").load("/FileStore/tables/retail-data/by-day/*.csv")

# Display the Data
display(retail_df)
```

#### Step 2: Exploring the Data
```python
# Show Schema
retail_df.printSchema()

# Summary Statistics
display(retail_df.describe())

# Exploring Specific Columns
display(retail_df.select("InvoiceNo", "Description"))

# Count Distinct Values
print(retail_df.select("StockCode").distinct().count())
```
#### Step 3: Basic Data Manipulations

```python
# Add a Revenue Column
from pyspark.sql.functions import col
retail_df = retail_df.withColumn("Revenue", col("Quantity") * col("UnitPrice"))

# Filter Data (High Revenue Transactions)
high_revenue_df = retail_df.filter(col("Revenue") > 500)
display(high_revenue_df)

# Group and Aggregate (Total Revenue by Country)
from pyspark.sql.functions import sum
revenue_by_country = retail_df.groupBy("Country").agg(sum("Revenue").alias("TotalRevenue"))
display(revenue_by_country.orderBy("TotalRevenue", ascending=False))
```

#### Step 4: Visualizations

```python
# Visualizing Total Revenue by Country
display(revenue_by_country)
```

#### Step 5: Clean Up Resources

- Terminate the Cluster:
    1. Go back to the "Clusters" page, select your cluster, and click "Terminate" to stop the cluster.
- Optional: Delete the Databricks Service:
    2. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

This lab provides a practical introduction to data processing and analysis using Azure Databricks with a focus on a retail dataset, ideal for understanding business analytics and data engineering in a cloud environment
