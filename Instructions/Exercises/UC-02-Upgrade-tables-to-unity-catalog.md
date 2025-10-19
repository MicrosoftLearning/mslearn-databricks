---
lab:
    title: 'Upgrade Tables to Unity Catalog'
---

# Upgrade Tables to Unity Catalog

Unity Catalog provides a centralized governance solution for data assets in Azure Databricks. When migrating from traditional Hive metastore tables to Unity Catalog, you need to upgrade existing tables to take advantage of Unity Catalog's enhanced security, governance, and management features.

In this exercise, you'll learn how to upgrade existing tables from the Hive metastore to Unity Catalog, understand the migration process, and explore the benefits of Unity Catalog governance.

This exercise should take approximately **30** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

This exercise includes a script to provision a new Azure Databricks workspace. The script attempts to create a *Premium* tier Azure Databricks workspace resource in a region in which your Azure subscription has sufficient quota for the compute cores required in this exercise; and assumes your user account has sufficient permissions in the subscription to create an Azure Databricks workspace resource. 

If the script fails due to insufficient quota or permissions, you can try to [create an Azure Databricks workspace interactively in the Azure portal](https://learn.microsoft.com/azure/databricks/getting-started/#--create-an-azure-databricks-workspace).

1. In a web browser, sign into the [Azure portal](https://portal.azure.com) at `https://portal.azure.com`.

2. Use the **[\>_]** button to the right of the search bar at the top of the page to create a new Cloud Shell in the Azure portal, selecting a ***PowerShell*** environment. The cloud shell provides a command line interface in a pane at the bottom of the Azure portal, as shown here:

    ![Azure portal with a cloud shell pane](./images/cloud-shell.png)

    > **Note**: If you have previously created a cloud shell that uses a *Bash* environment, switch it to ***PowerShell***.

3. Note that you can resize the cloud shell by dragging the separator bar at the top of the pane, or by using the **&#8212;**, **&#10530;**, and **X** icons at the top right of the pane to minimize, maximize, and close the pane. For more information about using the Azure Cloud Shell, see the [Azure Cloud Shell documentation](https://docs.microsoft.com/azure/cloud-shell/overview).

4. In the PowerShell pane, enter the following commands to clone this repo:

    ```
    rm -r mslearn-databricks -f
    git clone https://github.com/MicrosoftLearning/mslearn-databricks
    ```

5. After the repo has been cloned, enter the following command to run the **setup.ps1** script, which provisions an Azure Databricks workspace in an available region:

    ```
    ./mslearn-databricks/setup.ps1
    ```

6. If prompted, choose which subscription you want to use (this will only happen if you have access to multiple Azure subscriptions).
7. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer. While you are waiting, review the [What is Unity Catalog?](https://learn.microsoft.com/azure/databricks/data-governance/unity-catalog/) article in the Azure Databricks documentation.

## Open your Azure Databricks workspace

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace).

2. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).

3. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

## Upgrading Tables to Unity Catalog

In this exercise, you will learn essential techniques for upgrading tables to the Unity Catalog, a pivotal step in efficient data management. This exercise will cover various aspects, including analyzing existing data structures, applying migration techniques, evaluating transformation options, and upgrading metadata without moving data. Both SQL commands and user interface (UI) tools will be utilized for seamless upgrades.

By the end of this exercise, you will be able to analyze the current catalog, schema, and table structures in your data environment, execute methods to move data from Hive metastore to Unity Catalog including cloning and Create Table As Select (CTAS), assess and apply necessary data transformations during the migration process, utilize methods to upgrade table metadata while keeping data in its original location, and perform table upgrades using both SQL commands and user interface tools for efficient data management.

**Prerequisites:** To complete this exercise, you need account administrator capabilities and cloud storage resources to support the metastore. You must also have metastore admin capability to create and manage catalogs.

## Create a Notebook

You'll use a notebook to run SQL commands that demonstrate various table upgrade techniques.

1. In the sidebar, use the **(+) New** link to create a **Notebook**.
   
2. Change the default notebook name (**Untitled Notebook *[date]***) to `Upgrade tables to Unity Catalog` and in the **Connect** drop-down list, ensure you select a **classic compute cluster** rather than **Serverless**.

   > **Important**: Serverless compute will not work with the Hive metastore. You must use a classic compute cluster for this exercise.

## INCLUDE SETUP INSTRUCTIONS HERE

## Analyze Available Tables and Views

1. Add a new cell and run the following code to check your current catalog and schema:

    ```
    SELECT current_catalog(), current_schema();
    ```

2. Add a new cell and run the following code to show the list of tables within your schema:

    ```
    SHOW TABLES FROM example;
    ```

3. Add a new cell and run the following code to display a list of views in your schema:

    ```
    SHOW VIEWS FROM example;
    ```

## Explore the Hive Metastore Source Table

As part of the setup, you now have a table called *movies*, residing in a user-specific schema of the Hive metastore.

1. Add a new cell and run the following code to preview the data stored in this table:

    ```
    SELECT * 
    FROM IDENTIFIER('hive_metastore.' || user_hive_schema || '.movies')
    LIMIT 10
    ```

## Overview of Upgrade Methods

There are a few different ways to upgrade a table, but the method you choose will be driven primarily by how you want to treat the table data. If you wish to leave the table data in place, then the resulting upgraded table will be an external table. If you wish to move the table data into your Unity Catalog metastore, then the resulting table will be a managed table.

### Moving Table Data into the Unity Catalog Metastore

In this approach, table data will be copied from wherever it resides into the managed data storage area for the destination schema. The result will be a managed Delta table in your Unity Catalog metastore.

#### Cloning a Table

Cloning a table is optimal when the source table is Delta. It's simple to use, will copy metadata, and gives you the option of copying data (deep clone) or leaving it in place (shallow clone).

1. Add a new cell and run the following code to check the format of the source table:

    ```
    DESCRIBE EXTENDED IDENTIFIER('hive_metastore.' || user_hive_schema || '.movies')
    ```

   Notice that the *Provider* row shows the source is a Delta table, and the *Location* row shows that the table is stored in DBFS.

2. Add a new cell and run the following code to perform a deep clone operation:

    ```
    CREATE OR REPLACE TABLE movies_clone 
    DEEP CLONE IDENTIFIER('hive_metastore.' || user_hive_schema || '.movies')
    ```

3. Verify the cloned table by viewing your catalog in Catalog Explorer:
   - Select the catalog icon on the left
   - Expand your unique catalog name
   - Expand the **example** schema
   - Expand **Tables**
   - Notice that the **movies** table has been cloned as **movies_clone**

#### Create Table As Select (CTAS)

Using CTAS is a universally applicable technique that creates a new table based on the output of a `SELECT` statement. This will always copy the data, but no metadata will be copied.

1. Add a new cell and run the following code to copy the table using CTAS:

    ```
    CREATE OR REPLACE TABLE movies_ctas AS 
    SELECT * 
    FROM IDENTIFIER('hive_metastore.' || user_hive_schema || '.movies');
    ```

2. Add a new cell and run the following code to verify the table was created:

    ```
    SHOW TABLES IN example;
    ```

#### Applying Transformations during the Upgrade

CTAS offers the ability to transform the data while copying it. When migrating tables to Unity Catalog, it's a great time to consider whether your table structures still address your organization's business requirements.

1. Add a new cell and run the following code to create a transformed version of the table:

    ```
    CREATE OR REPLACE TABLE movies_transformed AS 
    SELECT
      id AS Movie_ID,
      title AS Movie_Title,
      genres AS Genres,
      upper(original_language) AS Original_Language,
      vote_average AS Vote_Average
    FROM IDENTIFIER('hive_metastore.' || user_hive_schema || '.movies');
    ```

2. Add a new cell and run the following code to view the transformed table:

    ```
    SELECT * 
    FROM movies_transformed;
    ```

## Upgrade External Tables (Example)

**Note**: This lab environment does not have access to external tables. This is an example of what you can do in your environment.

When upgrading external tables, some use cases may call for leaving the data in place, such as when data location is dictated by regulatory requirements, you cannot change the data format to Delta, or you want to avoid the time and cost of moving large datasets.

### Using the SYNC Command

The `SYNC` SQL command allows you to upgrade external tables in Hive Metastore to external tables in Unity Catalog without moving the data.

### Using Catalog Explorer to Upgrade Tables

You can also upgrade tables using the Catalog Explorer user interface:

1. Select the catalog icon on the left
2. Expand the **hive_metastore**
3. Expand your schema name in the hive metastore
4. Right-click on your schema name and select **Open in Catalog Explorer**
5. Select a table and click **Upgrade**
6. Select your destination catalog and schema
7. Configure the upgrade options as needed

For this exercise, you don't need to actually run the upgrade since it uses `SYNC` behind the scenes.

## Clean Up

When you've finished exploring Unity Catalog table upgrades, you can delete the resources you created to avoid unnecessary Azure costs.

When you've finished exploring Unity Catalog, you can delete the resources you created to avoid unnecessary Azure costs.

1. Close the Azure Databricks workspace browser tab and return to the Azure portal.
2. On the Azure portal, on the **Home** page, select **Resource groups**.
3. Select the resource group containing your Azure Databricks workspace (not the managed resource group).
4. At the top of the **Overview** page for your resource group, select **Delete resource group**. 
5. Enter the resource group name to confirm you want to delete it, and select **Delete**.

    After a few minutes, your resource group and the managed workspace resource group associated with it will be deleted.