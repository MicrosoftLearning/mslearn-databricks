---
lab:
    title: 'Use Delta Lake in Azure Databricks'
---

# Use Delta Lake in Azure Databricks

Delta Lake is an open source project to build a transactional data storage layer for Spark on top of a data lake. Delta Lake adds support for relational semantics for both batch and streaming data operations, and enables the creation of a *Lakehouse* architecture in which Apache Spark can be used to process and query data in tables that are based on underlying files in the data lake.

This lab will take approximately **30** minutes to complete.

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
    ./mslearn-databricks/setup.ps1
    ```

6. If prompted, choose which subscription you want to use (this will only happen if you have access to multiple Azure subscriptions).

7. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer. While you are waiting, review the [Introduction to Delta Lake](https://docs.microsoft.com/azure/databricks/delta/delta-intro) article in the Azure Databricks documentation.

## Open the Azure Databricks Workspace

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace)

2. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).

3. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

## Create a notebook and ingest data

Now let's create a Spark notebook and import the data that we'll work with in this exercise.

1. In the sidebar, use the **(+) New** link to create a **Notebook**.

1. Change the default notebook name (**Untitled Notebook *[date]***) to `Explore Delta Lake` and in the **Connect** drop-down list, select the **Serverless cluster** if it is not already selected. If the cluster is not running, it may take a minute or so to start.

1. In the first cell of the notebook, enter the following code, which creates a volume for storing product data.

     ```sql
    %sql
    CREATE VOLUME product_data_volume
     ```

1. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.

1. Under the existing code cell, use the **+ Code** icon to add a new code cell. Then in the new cell, enter and run the following Python code.

    ```python
    import requests

    # Download the CSV file
    url = "https://raw.githubusercontent.com/MicrosoftLearning/mslearn-databricks/main/data/products.csv"
    response = requests.get(url)
    response.raise_for_status()

    # Get the current catalog
    current_catalog = spark.sql("SELECT current_catalog()").collect()[0][0]

    # Write directly to Unity Catalog volume
    volume_path = f"/Volumes/{current_catalog}/default/product_data_volume/products.csv"
    with open(volume_path, "wb") as f:
        f.write(response.content)
    ```

    This Python code downloads a CSV file containing product data from a GitHub URL and saves it directly into a Unity Catalog volume in Databricks, using the current catalog context to dynamically construct the storage path.

1. Under the existing code cell, use the **+ Code** icon to add a new code cell. Then in the new cell, enter and run the following code to load the data from the file and view the first 10 rows.

    ```python
   df = spark.read.load(volume_path, format='csv', header=True)
   display(df.limit(10))
    ```

## Load the file data into a delta table

The data has been loaded into a dataframe. Let's persist it into a delta table.

1. Add a new code cell and use it to run the following code:

    ```python
    # Create the table if it does not exist. Otherwise, replace the existing table.
    df.writeTo("Products").createOrReplace()
    ```

    The data for a delta lake table is stored in Parquet format. A log file is also created to track modifications made to the data.

1. The file data in Delta format can be loaded into a **DeltaTable** object, which you can use to view and update the data in the table. Run the following code in a new cell to update the data; reducing the price of product 771 by 10%.

    ```python
    from delta.tables import DeltaTable

    # Reference the Delta table in Unity Catalog
    deltaTable = DeltaTable.forName(spark, "Products")

    # Perform the update
    deltaTable.update(
        condition = "ProductID == 771",
        set = { "ListPrice": "ListPrice * 0.9" })

    # View the updated data as a dataframe
    deltaTable.toDF().show(10)
    ```

    The update is persisted to the data in the delta folder, and will be reflected in any new dataframe loaded from that location.

1. Run the following code to create a new dataframe from the delta table data:

    ```python
   df = spark.read.load(volume_path, format='csv', header=True)
   display(df.limit(10))
    ```

## Explore logging and *time-travel*

Data modifications are logged, enabling you to use the *time-travel* capabilities of Delta Lake to view previous versions of the data. 

1. In a new code cell, use the following code to view the original version of the product data:

    ```python
    new_df = spark.read.option("versionAsOf", 0).table("Products")
    new_df.show(10)
    ```

1. The log contains a full history of modifications to the data. Use the following code to see a record of the last 10 changes:

    ```python
   deltaTable.history(10).show(10, False, True)
    ```

## Optimize table layout

The physical storage of table data and associated index data can be reorganized in order to reduce storage space and improve I/O efficiency when accessing the table. This is particularly useful after substantial insert, update, or delete operations on a table.

1. In a new code cell, use the following code to optimize the layout and clean up old versions of data files in the delta table:

     ```python
    spark.sql("OPTIMIZE Products")
    spark.sql("VACUUM Products RETAIN 168 HOURS") # 7 days
     ```

Delta Lake has a safety check to prevent you from running a dangerous VACUUM command. You can't set a retention period lower than 168 hours in Databricks **Serverless SQL** because it restricts unsafe file deletions to prevent data corruption, and serverless environments don't allow overriding this safety check.

> **Note**: If you run VACUUM on a delta table, you lose the ability to time travel back to a version older than the specified data retention period.

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
