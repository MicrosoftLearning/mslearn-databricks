---
lab:
    title: 'End-to-End Streaming Pipeline with Delta Live Tables in Azure Databricks'
---

# End-to-End Streaming Pipeline with Delta Live Tables in Azure Databricks
## Objective
The objective of this lab is to create an end-to-end streaming data pipeline using Delta Live Tables in Azure Databricks. You will learn how to ingest streaming data, transform it using Delta Live Tables, and visualize the processed data in real-time.

## Prerequisites
- Azure Subscription
- Azure Databricks Workspace
- Basic knowledge of Databricks and Delta Lake

## Sample Dataset
We will use a simulated IoT device data stream for this lab. The data will include temperature and humidity readings from various sensors.

## Steps
### Step 1: Set Up Azure Databricks Environment
1. Create a Databricks Workspace:
- Go to the Azure portal.
- Create a new Databricks workspace if you don't have one.
- Launch the Databricks workspace.

2. Create a Cluster:
- In the Databricks workspace, navigate to the "Clusters" section.
- Click "Create Cluster" and configure the cluster settings as needed.
- Start the cluster.

### Step 2: Create a Delta Live Table Pipeline
1. Create a New Pipeline:

- Navigate to the "Jobs" section in Databricks.
- Click on "Delta Live Tables" and then "Create Pipeline."
- Name your pipeline (e.g., "IoT Device Data Pipeline").

2. Define Data Sources:

- Click on "Add Data" and choose "Kafka" as the data source.
- Provide the Kafka server details and topic where the IoT data is being streamed.

3. Create a Notebook for Data Transformation:

- In the Databricks workspace, create a new notebook.
- Attach the notebook to your cluster.
- Add the following code to ingest and transform the streaming data:

```python
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Define the schema for the incoming data
schema = StructType([
    StructField("device_id", StringType(), True),
    StructField("timestamp", TimestampType(), True),
    StructField("temperature", DoubleType(), True),
    StructField("humidity", DoubleType(), True)
])

# Read streaming data from Kafka
raw_data = (spark
            .readStream
            .format("kafka")
            .option("kafka.bootstrap.servers", "<Kafka_Bootstrap_Servers>")
            .option("subscribe", "<Kafka_Topic>")
            .load())

# Parse the JSON data and apply the schema
parsed_data = (raw_data
               .selectExpr("CAST(value AS STRING)")
               .select(from_json(col("value"), schema).alias("data"))
               .select("data.*"))

# Write the data to a Delta table
query = (parsed_data
         .writeStream
         .format("delta")
         .option("checkpointLocation", "/tmp/checkpoints/iot_data")
         .start("/tmp/delta/iot_data"))
```

4. Add the Notebook to the Pipeline:

- In the Delta Live Table pipeline configuration, add the notebook you just created.

### Step 3: Transform Data Using Delta Live Tables
1. Create Delta Live Table Queries:

- Add a new notebook for data transformation steps.
- Attach the notebook to your cluster.
- Add the following code to create Delta Live Tables:

```python
import dlt

@dlt.table(
    name="raw_iot_data",
    comment="Raw IoT device data"
)
def raw_iot_data():
    return spark.readStream.format("delta").load("/tmp/delta/iot_data")

@dlt.table(
    name="transformed_iot_data",
    comment="Transformed IoT device data with derived metrics"
)
def transformed_iot_data():
    return (
        dlt.read("raw_iot_data")
        .withColumn("temperature_fahrenheit", col("temperature") * 9/5 + 32)
        .withColumn("humidity_percentage", col("humidity") * 100)
        .withColumn("event_time", current_timestamp())
    )
```

2. Add Transformation Notebook to the Pipeline:
- In the Delta Live Table pipeline configuration, add the transformation notebook.

### Step 4: Run the Pipeline
1. Start the Pipeline:
- In the Delta Live Table pipeline configuration, click "Start."
- Monitor the pipeline to ensure it runs successfully and processes the data.

### Step 5: Visualize the Processed Data
1. Create a Dashboard:

- In the Databricks workspace, navigate to "Dashboards."
- Create a new dashboard.

2. Add Visualizations:

- Use SQL to query the transformed IoT data and create visualizations.
- For example, create a line chart to visualize temperature trends over time:

```sql
SELECT event_time, temperature_fahrenheit
FROM transformed_iot_data
ORDER BY event_time
```

You have successfully created an end-to-end streaming pipeline using Delta Live Tables in Azure Databricks. You ingested streaming data from Kafka, transformed it using Delta Live Tables, and visualized the processed data in real-time.