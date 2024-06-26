# Exercise 01 - Explore Azure Databricks

## Objective
This exercise aims to familiarize you with Azure Databricks, focusing on setting up Databricks, creating and configuring clusters, and performing basic data analysis using Apache Spark and DataFrames.

## Requirements
An active Azure subscription. If you do not have one, you can sign up for a [free trial](https://azure.microsoft.com/en-us/free/).

## Estimated time: 30 minutes

## Step 1: Provision Azure Databricks (5 minutes)
- Login to Azure Portal:
    1. Go to Azure Portal and sign in with your credentials.
- Create Databricks Service:
    1. Navigate to "Create a resource" > "Analytics" > "Azure Databricks".
    2. Enter the necessary details like workspace name, subscription, resource group (create new or select existing), and location.
    3. Select the pricing tier (choose standard for this lab).
    4. Click "Review + create" and then "Create" once validation passes.

## Step 2: Launch Workspace and Create a Cluster (10 minutes)
- Launch Databricks Workspace:
    1. Once the deployment is complete, go to the resource and click "Launch Workspace".
- Create a Spark Cluster:
    1. In the Databricks workspace, click "Clusters" on the sidebar, then "+ Create Cluster".
    2. Specify the cluster name and select a runtime version of Spark.
    3. Choose the cluster mode as "Standard" and node type based on available options (choose smaller nodes for cost-efficiency).
    4. Click "Create Cluster".

## Step 3: Data Analysis with Spark (10 minutes)
- Import Data:
    1.  Navigate to "Data" in the sidebar, click "Add Data", and upload the [flights](../../Allfiles/Labs/01/flights.csv) dataset.
- Create a New Notebook:
    1. Go to "Workspace", create a new notebook (choose Python as the language).
    2. Attach the notebook to the cluster you created.
- Load Data into DataFrame and Analyze:
    1. Use the following sample code to load data into a DataFrame and perform simple data analysis:

```python
# File location and type
file_location = "/FileStore/tables/flights.csv"
file_type = "csv"

# CSV options
infer_schema = "true"
first_row_is_header = "true"
delimiter = ","

# Load CSV to DataFrame
df = spark.read.format(file_type) \
    .option("inferSchema", infer_schema) \
    .option("header", first_row_is_header) \
    .option("sep", delimiter) \
    .load(file_location)

display(df.limit(10))  # Display the first 10 rows
df.describe().show()  # Show statistics
```

## Step 4: Clean Up Resources (5 minutes)
- Terminate the Cluster:
    1. Go back to the "Clusters" page, select your cluster, and click "Terminate" to stop the cluster.

- Optional: Delete the Databricks Service:
    1. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

