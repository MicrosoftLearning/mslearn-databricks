---
lab:
    title: 'Create a data pipeline with Delta Live tables'
---

# Create a data pipeline with Delta Live tables

## Objective
Learn to set up data pipeline using Delta Live Tables in Azure Databricks to ingest, transform, and aggregate COVID-19 time-series data to provide insights into trends over time across different regions.

## Prerequisites
- An active Azure subscription. If you do not have one, you can sign up for a free trial.
- Basic knowledge of Python and SQL.
    • An Azure Databricks workspace with an active cluster.

## Estimated time: 60 minutes

### Step 1: Prepare Your Azure Databricks Environment
- Create an Azure Databricks Workspace: If you don’t have one, create it through the Azure portal.
- Launch a Cluster: Start a new Databricks cluster that supports Delta Lake (use the latest Databricks Runtime for full functionality).
    
### Step 2: Import Sample Dataset
For the lab, we’ll use a publicly available dataset, such as the COVID-19 Data Repository by the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University, which provides daily updated data files.

- Upload Dataset to DBFS (Databricks File System):
- Download a CSV file from the repository.
- Use the Data tab in Databricks to upload the CSV file to DBFS.
    
### Step 3: Create Initial Delta Table

#### Data Preparation
```sql
CREATE TABLE raw_covid_data
USING csv
OPTIONS (path '/FileStore/tables/covid_data.csv', header 'true', inferSchema 'true')
```

### Step 4: Develop Delta Live Tables Pipeline using SQL

#### Set Up a DLT Notebook:
- Open a new SQL notebook in Databricks and start defining the Delta Live Tables using SQL scripts. Ensure you have enabled the DLT SQL UI.
    
#### Define DLT Code
```sql
CREATE LIVE TABLE processed_covid_data
COMMENT "Formatted and filtered data for analysis."
AS
SELECT 
    to_date(date, 'MM/dd/yyyy') as report_date,
    country_region,
    confirmed,
    deaths,
    recovered
FROM raw_covid_data
WHERE country_region = 'US';

CREATE LIVE TABLE aggregated_covid_data
COMMENT "Aggregated daily data for the US with total counts."
AS
SELECT
    report_date,
    sum(confirmed) as total_confirmed,
    sum(deaths) as total_deaths,
    sum(recovered) as total_recovered
FROM processed_covid_data
GROUP BY report_date;
```

### Step 5: Deploy and Run Pipeline
- Deploy the Pipeline: Use the DLT UI to configure and initiate the pipeline. Set the update mode as required (Triggered or Continuous).
- Monitor Execution: View the pipeline's execution, inspect the output, and debug if needed.

### Step 6: Visualization and Analysis
- Create Visuals in Notebooks: Use display() on DataFrame queries to visualize data, e.g., trends over time for COVID-19 cases.
- Connect to BI Tools: Optionally, connect to external BI tools like Power BI to create dashboards.
