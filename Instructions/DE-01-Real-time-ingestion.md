# Exercise 01 - Real-time Ingestion and Processing with Spark Structured Streaming and Delta Lake with Azure Databricks

## Objective
In this lab, you will learn how to use Azure Databricks to set up a real-time data ingestion pipeline using Spark Structured Streaming and Delta Lake. By the end of this lab, you will be able to:

1. Set up Azure Databricks and create a cluster.
2. Ingest streaming data using Spark Structured Streaming.
3. Process and store streaming data using Delta Lake.
4. Query real-time data.

## Pre-requisites
- An active Azure subscription.
- Basic understanding of Apache Spark and Delta Lake.
- Basic knowledge of Azure Databricks.

## Sample Dataset
For this lab, we'll use a sample dataset that simulates real-time data from a device monitoring system. The dataset includes fields such as device_id, timestamp, temperature, and humidity.

## Step-by-Step Instructions
### Step 1: Set up Azure Databricks

1. Create an Azure Databricks Workspace

- Go to the Azure portal.
- Click on "Create a resource".
- Search for "Azure Databricks" and select it.
- Click "Create" and fill in the required details.
- Click "Review + create" and then "Create".
- Create a Databricks Cluster

2. In the Azure Databricks workspace, navigate to the "Clusters" tab.

- Click on "Create Cluster".
- Provide a name for the cluster and select the cluster mode and specifications.
- Click "Create Cluster".

### Step 2: Prepare the Streaming Data Source
1. Simulate a Streaming Data Source

- Create a directory in DBFS to store the sample data
```sh
    dbutils.fs.mkdirs("/mnt/device_data")
```

2. Upload a sample CSV file to 'mnt\device_data' directory. Use the following sample data and save it as 'device_data.csv'.

```sql
device_id,timestamp,temperature,humidity
1,2024-06-24 00:00:00,22.5,45
2,2024-06-24 00:00:01,23.0,44
3,2024-06-24 00:00:02,21.5,50
```

3. Upload this file using the Azure Databricks User Interface under the "Data" tab.

### Step 3: Ingest Streaming Data with Spark Structured Streaming

1. Create a Notebook in Azure Databricks

- Navigate to the "Workspace" tab and create a new notebook.
- Name the notebook "RealTimeIngestion".

2. Read the Streaming data
```python
from pyspark.sql.types import StructType, StructField, StringType, TimestampType, DoubleType

schema = StructType([
    StructField("device_id", StringType(), True),
    StructField("timestamp", TimestampType(), True),
    StructField("temperature", DoubleType(), True),
    StructField("humidity", DoubleType(), True)
])

raw_data = (spark.readStream
            .format("csv")
            .schema(schema)
            .option("header", "true")
            .load("/mnt/device_data"))
```

### Step 4: Process and Store Data with Delta Lake
1. Write Streaming Data to Delta Lake

- Add the following code to the notebook to write the streaming data into a Delta table.
```python
delta_table_path = "/mnt/delta/device_data"

query = (raw_data.writeStream
         .format("delta")
         .outputMode("append")
         .option("checkpointLocation", "/mnt/checkpoints/device_data")
         .start(delta_table_path))
```

2. Wait for the Streaming query to start
- Use the following code to ensure the streaming query is running.

```python
    query.awaitTermination()
```
### Step 5 - Query Real-time Data

1. Create a Delta Table
- Use the following code to create a Delta table.

```python
spark.sql(f"""
CREATE TABLE device_data_delta
USING DELTA
LOCATION '{delta_table_path}'
""")
```

2. Query the Real-Time data.
```python
    display(spark.sql("SELECT * FROM device_data_delta"))
```

### Step 6 - Monitoring and Management
1. Monitor the Streaming Query
- In the Azure Databricks, navigate to the "Streaming" tabl to monitor the progress of the streaming query.

2. Manage Delta Lake Tables
- Use the Delta Lake Commands to manage the tables for optimizing and vaccumming.

```Python
# Optimize the table
spark.sql("OPTIMIZE device_data_delta")

# Remove old data
spark.sql("VACUUM device_data_delta RETAIN 0 HOURS")

```

## Conclusion
In this lab, we have successfully set up a real-time data ingestion pipeline using Spark Structured Streaming and Delta Lake on Azure Databricks. We have learned how to ingest, process, and query real-time data using Databricks UI. This pipeline can be extended to handle more complex transformations and larger datasets as needed.