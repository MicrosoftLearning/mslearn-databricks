---
lab:
    title: 'Automating Data Ingestion and Processing using Azure Databricks'
---

# Automating Data Ingestion and Processing using Azure Databricks

## Objective
In this lab, you will learn how to automate data ingestion and processing using Azure Databricks and Automation Jobs. By the end of this lab, you will be able to:

1. Create and configure an Azure Databricks workspace.
2. Set up data ingestion from an external source.
3. Automate data processing using Databricks Jobs.
4. Schedule and monitor automated jobs.

## Sample Dataset
For this lab, we will use a sample dataset containing customer sales data. The dataset will be in CSV format with the following structure:

- customer_id: Unique identifier for each customer
- transaction_date: Date of the transaction
- transaction_amount: Amount of the transaction
- product_id: Unique identifier for each product
- product_category: Category of the product

## Prerequisites
- An active Azure subscription.
- Basic knowledge of Databricks, Python, and SQL.
- Azure Databricks workspace.

## Step-by-Step Instructions
### Step 1: Set Up Azure Databricks Workspace
1. Create a Databricks Workspace:

- Go to the Azure portal.
- Click on "Create a resource" and search for "Azure Databricks".
- Click on "Create" and fill in the required details (Workspace name, Subscription, Resource Group, Location, Pricing Tier).
- Click on "Review + create" and then "Create".

2. Launch the Workspace:

- Once the workspace is created, click on "Launch Workspace".
- This will take you to the Databricks web interface.

### Step 2: Create and Configure a Cluster
1. Create a New Cluster:

- In the Databricks workspace, navigate to the "Clusters" tab.
- Click on "Create Cluster".
- Provide a name for the cluster and select the appropriate configuration (e.g., Standard mode, Autoscaling, etc.).
-Click on "Create Cluster".

### Step 3: Ingest Data into Databricks
1. Upload the Sample Dataset:

- In the Databricks workspace, navigate to the "Data" tab.
- Click on "Add Data" and then "Upload File".
- Upload the sample CSV dataset.

2. Load the Data into a DataFrame:

- Create a new notebook by navigating to the "Workspace" tab and clicking on "Create" > "Notebook".
- Choose a name for your notebook and select the language (Python).
- Attach the notebook to your cluster.

```python
# Load the sample dataset into a DataFrame
df = spark.read.csv('/FileStore/tables/sample_sales_data.csv', header=True, inferSchema=True)
df.show()
```

### Step 4: Automate Data Processing with Azure Databricks Jobs
1. Create a Data Processing Notebook:

- In the same or a new notebook, write the data processing logic. For example, aggregate sales data by product category:

```python
from pyspark.sql.functions import col, sum

# Aggregate sales data by product category
sales_by_category = df.groupBy('product_category').agg(sum('transaction_amount').alias('total_sales'))
sales_by_category.show()

```
2. Create a Databricks Job:

- Navigate to the "Jobs" tab in the Databricks workspace.
- Click on "Create Job".
- Provide a name for the job and specify the notebook you created as the task.
- Configure the cluster, schedule, and other settings as required.
- Click on "Create".

### Step 5: Schedule and Monitor Jobs
1. Schedule the Job:
- In the job configuration, set up a schedule for the job (e.g., daily, weekly).
- Configure any necessary parameters and alerts.

2. Monitor Job Runs:
- Monitor the job runs from the "Jobs" tab.
- Check the job run history, logs, and any alerts for successful or failed runs.

By following these steps, you have successfully set up and automated data ingestion and processing using Azure Databricks and Automation Jobs. You can now scale this solution to handle more complex data pipelines and integrate with other Azure services for a robust data processing architecture.