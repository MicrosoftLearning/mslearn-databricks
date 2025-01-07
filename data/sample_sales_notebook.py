# Databricks notebook source
from pyspark.sql.types import *
from pyspark.sql.functions import *
#Define the schema used in the table
salesSchema = StructType([
    StructField("Date", DateType()),
    StructField("Product", StringType()),
    StructField("Quantity", IntegerType()),
    StructField("Price", FloatType())
])
#Load the data from the CSV file into a Dataframe
df = spark.read.load('/FileStore/sample_sales.csv', format='csv', header='true', schema=salesSchema)
display(df)

# COMMAND ----------

#Create a new column Revenue as the product of Quantity and Price
df = df.withColumn("Revenue", col("Quantity") * col("Price"))
display(df)
