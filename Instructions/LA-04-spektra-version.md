# Exercise 04 - Explore features of Delta Lake

## Objective
Understand and experiment with Delta Lake's ACID transactions, schema enforcement, time travel, and performance optimization.

## Prerequisites
- An active Azure subscription. If you do not have one, you can sign up for a free trial.
- Basic knowledge of Python and SQL.
- An Azure Databricks workspace with an active cluster.

## Estimated time: 120 minutes

## Step 1: Environment Setup
Create an Azure Databricks Workspace (if not already available).

### Launch a Spark Cluster:
    • Navigate to the “Clusters” section of your Databricks workspace.
    • Create a new cluster, selecting a Databricks Runtime version that supports Delta Lake (typically the latest version).
    • Configure the cluster with adequate resources, considering the number of participants and the lab activities planned.

### Step 2: Create Datasets
We will generate a simple dataset directly within a Databricks notebook:

```python
# Sample data generation
data = spark.createDataFrame([
    (1, "John Doe", 28),
    (2, "Jane Smith", 34),
    (3, "Jake Long", 42)
], ["id", "name", "age"])

# Write the DataFrame as a Delta table
data.write.format("delta").mode("overwrite").save("/mnt/delta/sample_data")
```

### Step 3: Working with ACID Transactions
Learn how Delta Lake handles ACID Transactions

```python
from delta.tables import DeltaTable
deltaTable = DeltaTable.forPath(spark, "/mnt/delta/sample_data")

# Demonstrate an update
deltaTable.update(
    condition="id = 1",
    set={"age": "29"}
)
```

### Step 4: Schema Enforcement and Evolution
Explore how Delta Lake enforces and evolves schema

```python
# Try to write mismatched schema
new_data = spark.createDataFrame([
    (4, "Emily Young", "twenty-nine")
], ["id", "name", "age"])

# This will raise an error
try:
    new_data.write.format("delta").mode("append").save("/mnt/delta/sample_data")
except Exception as e:
    print("Schema mismatch error:", e)

# Enable schema merging
new_data.write.format("delta").option("mergeSchema", "true").mode("append").save("/mnt/delta/sample_data")
```

### Step 5: Time Travel
Understand and use Delta Lake’s time travel feature to access historical data versions.

```python
# Access a previous version of the table
df_version0 = spark.read.format("delta").option("versionAsOf", 0).load("/mnt/delta/sample_data")
df_version0.show()
```

### Step 6: Performance Optimization
Learn how to optimize Delta Lake tables for performance.

```python
# Optimize and clean up the table
spark.sql("OPTIMIZE '/mnt/delta/sample_data'")
spark.sql("VACUUM '/mnt/delta/sample_data' RETAIN 24 HOURS")
```

### Step 7: Clean Up Resources
- Terminate the Cluster:
    1. Go back to the "Clusters" page, select your cluster, and click "Terminate" to stop the cluster.
- Optional: Delete the Databricks Service:
    2. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.
