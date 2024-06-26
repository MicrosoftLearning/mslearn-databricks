# Exercise 06 - Deploy workloads with Azure Databricks Workflows

## Objective
To develop proficiency in designing, implementing, and automating a data pipeline using Azure Databricks

## Prerequisites
- An active Azure subscription. If you do not have one, you can sign up for a free trial.
- Basic knowledge of Python and SQL.
- An Azure Databricks workspace with an active cluster.

## Estimated time: 60 minutes

## Step 1: Setup Azure Databricks Environment
- Create an Azure Databricks Workspace:
    1. Log in to the Azure Portal.
    2. Navigate to 'Create a resource', select 'Analytics', and then choose 'Azure Databricks'.
    3. Fill in the necessary details and create the workspace.
- Launch the Workspace:
    1. Once created, go to the resource and click on 'Launch Workspace'.
- Create a Cluster:
    1. Inside the workspace, go to the 'Clusters' section and click 'Create Cluster'.
    2. Specify the cluster configuration (e.g., Databricks Runtime version, Node type).
    3. Enable auto-scaling and start the cluster.
        
## Step 2: Data Ingestion
- Upload Dataset:
    1. Navigate to 'Data' in the sidebar, then 'Add Data', and upload the flight data CSV file to DBFS (Databricks File System).
- Create a New Notebook:
    1. Go to the 'Workspace' tab, create a new notebook.
    2. Set the default language (Python, Scala, SQL, or R) and attach the notebook to your cluster.
- Load Data into DataFrame:
    1. Use Spark DataFrame APIs to read the CSV file into a DataFrame.
    2. Display the DataFrame to verify the data is loaded correctly.

```python
    df = spark.read.csv("/FileStore/tables/flight_data.csv", header=True, inferSchema=True)
    display(df)
```

## Step 3: Data Processing
- Data Cleaning:
    1. Handle missing values, remove duplicates, and filter out irrelevant records.
- Feature Engineering:
    1. Calculate new metrics such as 'On Time Percentage' and 'Average Delay' per airline and airport.

## Step 4: Data Analysis
- Exploratory Data Analysis (EDA):
    1. Analyze trends and patterns in the data.
    2. Generate visualizations using Databricks’ built-in visualization tools or libraries like Matplotlib/Seaborn.
- Insight Generation:
    1. Identify the top 5 airlines and airports with the least and most delays.

## Step 5: Build and Schedule the Workflow
- Define Jobs:
    1. Use the 'Jobs' tab to create new jobs that point to your notebook.
    2. Set up parameters and configure the job schedule using cron syntax.
- Triggering and Dependencies:
    1. Set dependencies so that some tasks are only run after successful completion of others.

## Step 6: Monitoring and Optimization
- Monitor Job Runs:
    1. Use the 'Jobs' dashboard to monitor the status and performance of scheduled jobs.
    
Analyze logs and metrics to optimize cluster performance.