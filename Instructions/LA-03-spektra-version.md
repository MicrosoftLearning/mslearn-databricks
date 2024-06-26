# Exercise 03 - Data Cleansing and Transformations using Apache Spark

## Objective
Learn to perform essential data cleansing and transformation operations using Apache Spark in an Azure Databricks environment.

## Prerequisites
- An active Azure subscription. If you do not have one, you can sign up for a free trial.
- Basic knowledge of Python and SQL.
- An Azure Databricks workspace with an active cluster.

## Estimated time: 120 minutes

## Lab Setup:
- Create a New Notebook: Name it "Data Cleansing and Transformation Lab".
- Attach the Notebook to a Cluster: Ensure the cluster is running Databricks Runtime that includes Apache Spark.

### Step 1: Data Loading and Initial Exploration

```python
# Task 1: Load the sample dataset /databricks-datasets/samples/population-vs-price/data_geo.csv into a Spark DataFrame.
df = spark.read.csv("/databricks-datasets/samples/population-vs-price/data_geo.csv", header=True, inferSchema=True)
display(df)

# Task 2: Display the DataFrame schema and print the first 10 rows
df.printSchema()
display(df.limit(10))

# Task 3: Use descriptive statistics to understand the dataset
display(df.describe())
```

### Step 2: Data Cleansing

```python
# Task 1: Identify missing values and fill them with appropriate default values or estimates.
for column in df.columns:
    if df.filter(df[column].isNull()).count() > 0:
        df = df.fillna({column: 'Unknown'})  # Replace 'Unknown' with a relevant value or calculation

# Task 2: Detect and remove duplicate records
df = df.dropDuplicates()

# Task 3: Fix incorrect data formats and types (e.g., converting strings to floats or dates)
from pyspark.sql.functions import col
df = df.withColumn("2020 Population", col("2020 Population").cast("float"))
```

### Step 3: Data Transformation

```python
# Task 1: Normalize a numerical column (e.g., scale '2020 Population' to range between 0 and 1)
from pyspark.sql.functions import min, max
min_val = df.select(min("2020 Population")).first()[0]
max_val = df.select(max("2020 Population")).first()[0]
df = df.withColumn("Normalized Population", (col("2020 Population") - min_val) / (max_val - min_val))

# Task 2: Create a new categorical column based on numerical data (e.g., categorize '2020 Population' into 'Low', 'Medium', 'High').
df = df.withColumn("Population Category", when(col("2020 Population") < 1000000, "Low")
                   .when(col("2020 Population") < 10000000, "Medium")
                   .otherwise("High"))

# Task 3: Group data by the new category and compute aggregates like mean price
from pyspark.sql.functions import avg
grouped_data = df.groupBy("Population Category").agg(avg("2015 median sales price").alias("Average Price"))
display(grouped_data)
```

### Step 4: Clean Up Resources

- Terminate the Cluster:
    1. Go back to the "Clusters" page, select your cluster, and click "Terminate" to stop the cluster.
- Optional: Delete the Databricks Service:
    2. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

This hands-on approach not only teaches the fundamental skills in data processing with Spark but also encourages critical thinking about data handling and manipulation in real-world scenarios.
