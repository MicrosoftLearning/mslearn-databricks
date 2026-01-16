---
lab:
    title: 'Deploy workloads with Azure Databricks Lakeflow jobs'
---

# Deploy workloads with Azure Databricks Lakeflow jobs

Azure Databricks Lakeflow jobs provide a robust platform for deploying workloads efficiently. With features like Azure Databricks Jobs and Delta Live Tables, users can orchestrate complex data processing, machine learning, and analytics pipelines.

This lab will take approximately **40** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

This exercise includes a script to provision a new Azure Databricks workspace. The script attempts to create a *Premium* tier Azure Databricks workspace resource in a region in which your Azure subscription has sufficient quota for the compute cores required in this exercise; and assumes your user account has sufficient permissions in the subscription to create an Azure Databricks workspace resource. If the script fails due to insufficient quota or permissions, you can try to [create an Azure Databricks workspace interactively in the Azure portal](https://learn.microsoft.com/azure/databricks/getting-started/#--create-an-azure-databricks-workspace).

1. In a web browser, sign into the [Azure portal](https://portal.azure.com) at `https://portal.azure.com`.
2. Use the **[\>_]** button to the right of the search bar at the top of the page to create a new Cloud Shell in the Azure portal, selecting a ***PowerShell*** environment. The cloud shell provides a command line interface in a pane at the bottom of the Azure portal, as shown here:

    ![Azure portal with a cloud shell pane](./images/cloud-shell.png)

    > **Note**: If you have previously created a cloud shell that uses a *Bash* environment, switch it to ***PowerShell***.

3. Note that you can resize the cloud shell by dragging the separator bar at the top of the pane, or by using the **&#8212;**, **&#10530;**, and **X** icons at the top right of the pane to minimize, maximize, and close the pane. For more information about using the Azure Cloud Shell, see the [Azure Cloud Shell documentation](https://docs.microsoft.com/azure/cloud-shell/overview).

4. In the PowerShell pane, enter the following commands to clone this repo:

     ```powershell
    rm -r mslearn-databricks -f
    git clone https://github.com/MicrosoftLearning/mslearn-databricks
     ```

5. After the repo has been cloned, enter the following command to run the **setup.ps1** script, which provisions an Azure Databricks workspace in an available region:

     ```powershell
    ./mslearn-databricks/setup-serverless.ps1
     ```

6. If prompted, choose which subscription you want to use (this will only happen if you have access to multiple Azure subscriptions).

7. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer. While you are waiting, review the [Lakeflow jobs](https://learn.microsoft.com/azure/databricks/jobs/) article in the Azure Databricks documentation.

## Open the Azure Databricks Workspace

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace)

1. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).

1. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

## Create a notebook

1. In the sidebar, use the **(+) New** link to create a **Notebook**.

1. Change the default notebook name (**Untitled Notebook *[date]***) to `ETL task` and in the **Connect** drop-down list, select **Serverless** compute if it is not already selected. If the compute is not running, it may take a minute or so to start.

## Ingest data

1. In the first cell of the notebook, enter the following code to create a volume for storing some lab files.

    ```sql
    %sql
    CREATE VOLUME IF NOT EXISTS spark_lab
    ```

1. Add a new code cell and use it to run the following code, which uses *Python* to download data files from GitHub into your volume.

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

1. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.
1. Under the output, use the **+ Code** icon to add a new code cell, and use it to run the following code, which defines a schema for the data:

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

## Create a job task

1. Under the existing code cell, use the **+ Code** icon to add a new code cell. Then in the new cell, enter and run the following code to remove duplicate rows and to replace the `null` entries with the correct values:

     ```python
    from pyspark.sql.functions import col
    df = df.dropDuplicates()
    df = df.withColumn('Tax', col('UnitPrice') * 0.08)
    df = df.withColumn('Tax', col('Tax').cast("float"))
     ```
    > **Note**: After updating the values in the **Tax** column, its data type is set to `float` again. This is due to its data type changing to `double` after the calculation is performed. Since `double` has a higher memory usage than `float`, it is better for performance to type cast the column back to `float`.

2. In a new code cell, run the following code to aggregate and group the order data:

    ```python
   yearlySales = df.select(year("OrderDate").alias("Year")).groupBy("Year").count().orderBy("Year")
   display(yearlySales)
    ```

## Build the Workflow

Azure Databricks manages the task orchestration, cluster management, monitoring, and error reporting for all of your jobs. You can run your jobs immediately, periodically through an easy-to-use scheduling system, whenever new files arrive in an external location, or continuously to ensure an instance of the job is always running.

1. In your workspace, click ![Workflows icon.](./images/WorkflowsIcon.svg) **Jobs & Pipelines** in the sidebar.

2. In the Jobs & Pipelines pane, select **Create**, then **Job**.

3. Change the default job name (**New job *[date]***) to `ETL job`.

4. Configure the job with the following settings:
    - **Task name**: `Run ETL task notebook`
    - **Type**: Notebook
    - **Source**: Workspace
    - **Path**: *Select your* ETL task *notebook*
    - **Cluster**: *Select Serverless*

5. Select **Create task**.

6. Select **Run now**.

7. After the job starts running, you can monitor its execution by selecting **Job Runs** in the left sidebar.

8. After the job run succeeds, you can select it and verify its output.

Additionally, you can run jobs on a triggered basis, for example, running a workflow on a schedule. To schedule a periodic job run, you can open the job task and add a trigger.

## Clean up

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
