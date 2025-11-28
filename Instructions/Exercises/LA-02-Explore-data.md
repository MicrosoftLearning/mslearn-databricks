---
lab:
    title: 'Explore data with Azure Databricks'
---

# Explore data with Azure Databricks

Azure Databricks is a Microsoft Azure-based version of the popular open-source Databricks platform. 

Azure Databricks facilitates exploratory data analysis (EDA), allowing users to quickly discover insights and drive decision-making. It integrates with a variety of tools and techniques for EDA, including statistical methods and visualizations, to summarize data characteristics and identify any underlying issues.

This exercise should take approximately **30** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

This exercise includes a script to provision a new Azure Databricks workspace. The script attempts to create a *Premium* tier Azure Databricks workspace resource in a region in which your Azure subscription has sufficient quota for the compute cores required in this exercise; and assumes your user account has sufficient permissions in the subscription to create an Azure Databricks workspace resource. 

If the script fails due to insufficient quota or permissions, you can try to [create an Azure Databricks workspace interactively in the Azure portal](https://learn.microsoft.com/azure/databricks/getting-started/#--create-an-azure-databricks-workspace).

1. In a web browser, sign into the [Azure portal](https://portal.azure.com) at `https://portal.azure.com`.
1. Use the **[\>_]** button to the right of the search bar at the top of the page to create a new Cloud Shell in the Azure portal, selecting a ***PowerShell*** environment. The cloud shell provides a command line interface in a pane at the bottom of the Azure portal, as shown here:

    ![Azure portal with a cloud shell pane](./images/cloud-shell.png)

    > **Note**: If you have previously created a cloud shell that uses a *Bash* environment, switch it to ***PowerShell***.

1. Note that you can resize the cloud shell by dragging the separator bar at the top of the pane, or by using the **&#8212;**, **&#10530;**, and **X** icons at the top right of the pane to minimize, maximize, and close the pane. For more information about using the Azure Cloud Shell, see the [Azure Cloud Shell documentation](https://docs.microsoft.com/azure/cloud-shell/overview).

1. In the PowerShell pane, enter the following commands to clone this repo:

    ```
    rm -r mslearn-databricks -f
    git clone https://github.com/MicrosoftLearning/mslearn-databricks
    ```

1. After the repo has been cloned, enter the following command to run the **setup.ps1** script, which provisions an Azure Databricks workspace in an available region:

    ```
    ./mslearn-databricks/setup.ps1
    ```

1. If prompted, choose which subscription you want to use (this will only happen if you have access to multiple Azure subscriptions).
1. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer. While you are waiting, review the [Exploratory data analysis on Azure Databricks](https://learn.microsoft.com/azure/databricks/exploratory-data-analysis/) article in the Azure Databricks documentation.

## Open the Azure Databricks Workspace

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace)

1. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).

1. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.
    
## Create a Notebook

1. In the sidebar, use the **(+) New** link to create a **Notebook**.
   
1. Change the default notebook name (**Untitled Notebook *[date]***) to `Explore data with Spark` and in the **Connect** drop-down list, select **Serverless** compute if it is not already selected. If the compute is not running, it may take a minute or so to start.

## Ingest data

1. In the first cell of the notebook, enter the following code to create a volume for storing some lab files.

    ```sql
    %sql
    CREATE VOLUME IF NOT EXISTS spark_lab
    ```

1. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.

2. Add a new code cell and use it to run the following code, which uses *Python* to download data files from GitHub into your volume.

    ```python
    import requests

    # Define the current catalog
    catalog_name = spark.sql("SELECT current_catalog()").collect()[0][0]

    # Define the base path using the current catalog
    volume_base = f"/Volumes/{catalog_name}/default/spark_lab"

    # List of files to download
    files = ["2019.csv", "2020.csv", "2021.csv"]

    # Download each file
    for file in files:
        url = f"https://raw.githubusercontent.com/MicrosoftLearning/mslearn-databricks/main/data/{file}"
        response = requests.get(url)
        response.raise_for_status()

        # Write to Unity Catalog volume
        with open(f"{volume_base}/{file}", "wb") as f:
            f.write(response.content)
    ```

3. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.

## Query data in files

1. Move the mouse under the existing code cell, and use the **+ Code** icon that appears to add a new code cell. Then in the new cell, enter and run the following code to load the data from the files and view the first 100 rows.

    ```python
    df = spark.read.load(f'/Volumes/{catalog_name}/default/spark_lab/*.csv', format='csv')
    display(df.limit(100))
    ```

1. View the output and note that the data in the file relates to sales orders, but doesn't include the column headers or information about the data types. To make more sense of the data, you can define a *schema* for the dataframe.

1. Add a new code cell and use it to run the following code, which defines a schema for the data:

    ```python
   from pyspark.sql.types import *
   from pyspark.sql.functions import *
   orderSchema = StructType([
        StructField("SalesOrderNumber", StringType()),
        StructField("SalesOrderLineNumber", IntegerType()),
        StructField("OrderDate", DateType()),
        StructField("CustomerName", StringType()),
        StructField("Email", StringType()),
        StructField("Item", StringType()),
        StructField("Quantity", IntegerType()),
        StructField("UnitPrice", FloatType()),
        StructField("Tax", FloatType())
   ])
   df = spark.read.load(f'/Volumes/{catalog_name}/default/spark_lab/*.csv', format='csv', schema=orderSchema)
   display(df.limit(100))
    ```

1. Observe that this time, the dataframe includes column headers. Then add a new code cell and use it to run the following code to display details of the dataframe schema, and verify that the correct data types have been applied:

    ```python
   df.printSchema()
    ```

## Query data using Spark SQL

1. Add a new code cell and use it to run the following code:

    ```python
   df.createOrReplaceTempView("salesorders")
   spark_df = spark.sql("SELECT * FROM salesorders")
   display(spark_df)
    ```

   The native methods of the dataframe object you used previously enable you to query and analyze data quite effectively. However, many data analysts are more comfortable working with SQL syntax. Spark SQL is a SQL language API in Spark that you can use to run SQL statements, or even persist data in relational tables.

   The code you just ran creates a relational *view* of the data in a dataframe, and then uses the **spark.sql** library to embed Spark SQL syntax within your Python code and query the view and return the results as a dataframe.

## View results as a visualization

1. In a new code cell, run the following code to query the **salesorders** table:

    ```sql
   %sql
    
   SELECT * FROM salesorders
    ```

1. Above the table of results, select **+** and then select **Visualization** to view the visualization editor, and then apply the following options:
    - **Visualization type**: Bar
    - **X Column**: Item
    - **Y Column**: *Add a new column and select* **Quantity**. *Apply the* **Sum** *aggregation*.
    
1. Save the visualization and then re-run the code cell to view the resulting chart in the notebook.

## Get started with matplotlib

1. In a new code cell, run the following code to retrieve some sales order data into a dataframe:

    ```python
   sqlQuery = "SELECT CAST(YEAR(OrderDate) AS CHAR(4)) AS OrderYear, \
                   SUM((UnitPrice * Quantity) + Tax) AS GrossRevenue \
            FROM salesorders \
            GROUP BY CAST(YEAR(OrderDate) AS CHAR(4)) \
            ORDER BY OrderYear"
   df_spark = spark.sql(sqlQuery)
   df_spark.show()
    ```

1. Add a new code cell and use it to run the following code, which imports the **matplotlib** and uses it to create a chart:

    ```python
   from matplotlib import pyplot as plt
    
   # matplotlib requires a Pandas dataframe, not a Spark one
   df_sales = df_spark.toPandas()
   # Create a bar plot of revenue by year
   plt.bar(x=df_sales['OrderYear'], height=df_sales['GrossRevenue'])
   # Display the plot
   plt.show()
    ```

1. Review the results, which consist of a column chart with the total gross revenue for each year. Note the following features of the code used to produce this chart:
    - The **matplotlib** library requires a Pandas dataframe, so you need to convert the Spark dataframe returned by the Spark SQL query to this format.
    - At the core of the **matplotlib** library is the **pyplot** object. This is the foundation for most plotting functionality.

1. The default settings result in a usable chart, but there’s considerable scope to customize it. Add a new code cell with the following code and run it:

    ```python
   # Clear the plot area
   plt.clf()
   # Create a bar plot of revenue by year
   plt.bar(x=df_sales['OrderYear'], height=df_sales['GrossRevenue'], color='orange')
   # Customize the chart
   plt.title('Revenue by Year')
   plt.xlabel('Year')
   plt.ylabel('Revenue')
   plt.grid(color='#95a5a6', linestyle='--', linewidth=2, axis='y', alpha=0.7)
   plt.xticks(rotation=45)
   # Show the figure
   plt.show()
    ```

1. A plot is technically contained with a **Figure**. In the previous examples, the figure was created implicitly for you; but you can create it explicitly. Try running the following in a new cell:

    ```python
   # Clear the plot area
   plt.clf()
   # Create a Figure
   fig = plt.figure(figsize=(8,3))
   # Create a bar plot of revenue by year
   plt.bar(x=df_sales['OrderYear'], height=df_sales['GrossRevenue'], color='orange')
   # Customize the chart
   plt.title('Revenue by Year')
   plt.xlabel('Year')
   plt.ylabel('Revenue')
   plt.grid(color='#95a5a6', linestyle='--', linewidth=2, axis='y', alpha=0.7)
   plt.xticks(rotation=45)
   # Show the figure
   plt.show()
    ```

1. A figure can contain multiple subplots, each on its own axis. Use this code to create multiple charts:

    ```python
   # Clear the plot area
   plt.clf()
   # Create a figure for 2 subplots (1 row, 2 columns)
   fig, ax = plt.subplots(1, 2, figsize = (10,4))
   # Create a bar plot of revenue by year on the first axis
   ax[0].bar(x=df_sales['OrderYear'], height=df_sales['GrossRevenue'], color='orange')
   ax[0].set_title('Revenue by Year')
   # Create a pie chart of yearly order counts on the second axis
   yearly_counts = df_sales['OrderYear'].value_counts()
   ax[1].pie(yearly_counts)
   ax[1].set_title('Orders per Year')
   ax[1].legend(yearly_counts.keys().tolist())
   # Add a title to the Figure
   fig.suptitle('Sales Data')
   # Show the figure
   plt.show()
    ```

> **Note**: To learn more about plotting with matplotlib, see the [matplotlib documentation](https://matplotlib.org/).

## Use the seaborn library

1. Add a new code cell and use it to run the following code, which uses the **seaborn** library (which is built on matplotlib and abstracts some of its complexity) to create a chart:

    ```python
   import seaborn as sns
   
   # Clear the plot area
   plt.clf()
   # Create a bar chart
   ax = sns.barplot(x="OrderYear", y="GrossRevenue", data=df_sales)
   plt.show()
    ```

1. The **seaborn** library makes it simpler to create complex plots of statistical data, and enables you to control the visual theme for consistent data visualizations. Run the following code in a new cell:

    ```python
   # Clear the plot area
   plt.clf()
   
   # Set the visual theme for seaborn
   sns.set_theme(style="whitegrid")
   
   # Create a bar chart
   ax = sns.barplot(x="OrderYear", y="GrossRevenue", data=df_sales)
   plt.show()
    ```

1. Like matplotlib. seaborn supports multiple chart types. Run the following code to create a line chart:

    ```python
   # Clear the plot area
   plt.clf()
   
   # Create a bar chart
   ax = sns.lineplot(x="OrderYear", y="GrossRevenue", data=df_sales)
   plt.show()
    ```

> **Note**: To learn more about plotting with seaborn, see the [seaborn documentation](https://seaborn.pydata.org/index.html).

## Clean up

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
