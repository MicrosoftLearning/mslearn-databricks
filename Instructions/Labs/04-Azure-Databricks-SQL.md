---
lab:
    title: 'Use a SQL Warehouse in Azure Databricks'
    module: 'Get Started with Azure Databricks'
---

# Use a SQL Warehouse in Azure Databricks

SQL is an industry-standard language for querying and manipulating data. Many data analysts perform data analytics by using SQL to query tables in a relational database. Azure Databricks includes SQL functionality that builds on Spark and Delta Lake technologies to provide a relational database layer over files in a data lake.

This lab will take approximately **30** minutes to complete.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access and sufficient quota in at least one region to provision an Azure Databricks SQL Warehouse.

## Provision an Azure Databricks workspace

In this exercise, you'll need a premium-tier Azure Databricks workspace.

1. In a web browser, sign into the [Azure portal](https://portal.azure.com) at `https://portal.azure.com`.
2. Use the **+ Create a resource** button to create a new **Azure Databricks** resource with the following settings:
    - **Subscription**: *Select your Azure subscription*.
    - **Resource group**: *Create a new resource group with a name of your choice*.
    - **Workspace name**: *Enter a name for your workspace*
    - **Region**: *Choose a region*.
    - **Pricing Tier**: Premium (+ Role-based access controls)

3. Wait for the resource to be deployed - this typically takes around 3 minutes, but in some cases may take longer. While you are waiting, review the [What is Databricks SQL?](https://docs.microsoft.com/azure/databricks/scenarios/what-is-databricks-sql) article in the Azure Databricks documentation.

## View and start a SQL Warehouse

1. When the Azure Databricks workspace resource has been deployed, go to it in the Azure portal.
2. In the **Overview** page for your Azure Databricks workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.
3. If a **What's your current data project?** message is displayed, select **Finish** to close it. Then view the Azure Databricks workspace portal and note that the bar on the left side contains icons for the various tasks you can perform. The bar expands to show the names of the task categories.
4. In the sidebar on the left, expand **[D] Data Science & Engineering** and select **[S] SQL**. to change the portal interface to reflect the SQL persona (this persona is only available in *premium-tier* workspaces).
5. In the **Get Started** pane, select **Review SQL Warehouses** (or alternatively, in the sidebar, select **SQL Warehouses**).
6. Observe that the workspace already includes a SQL Warehouse named **Starter Warehouse**. If the current status is **Stopped**, use the **Start** button to start it (which may take a minute or two).

    **Note**: If the SQL Warehouse fails to launch, you may have insufficient quota in your subscription for the region where the Azure Databricks workspace is deployed. In this case, you may need to delete your workspace and create a new one in another region.

## Create a database

1. When your SQL Warehouse is *running*, close the **Review SQL warehouses** pane on the left. Then in the sidebar, select **SQL Editor**.
2. In the **Schema browser** pane, observe that the hive metastore contains a database named **default**.
3. In the **New query** pane, enter the following SQL code:

    ```sql
    CREATE SCHEMA adventureworks;
    ```
4. Use the **Run All** button to run the SQL code.
5. When the code has been successfully executed, in the **Schema browser** pane, use the **&#8635;** button to refresh the list. Then select the **default** database to reveal the list of databases and select **adventureworks**. The database has been created, but contains no tables.

You can use the **default** database for your tables, but when building an analytical data store its best to create custom databases for specific data.

## Create a table

1. In the sidebar, select **(+) Create** and then select **Table**.
2. In the **Upload file** area, select **browse**. Then in the **Open** dialog box, enter `https://raw.githubusercontent.com/MicrosoftLearning/mslearn-databricks/main/Allfiles/Labs/04/data/products.csv` and select **Open**.

    > **Tip**: If your browser or operating system doesn't support entering a URL in the **File** box, download the CSV file to your computer and then upload it from the local folder where you saved it.

3. In the **Create table in Databricks SQL** page, select the **adventureworks** database and set the table name to **products**. Then select **Create**.
4. When the table has been created, review its details.

The ability to create a table by importing data from a file makes it easy to populate a database. You can also use Spark SQL to create tables using code. The tables themselves are metadata definitions in the hive metastore, and the data they contain is stored in Delta format in Databricks File System (DBFS) storage.

## Create a query

1. In the sidebar, select **(+) Create** and then select **Query**.
2. In the **Schema browser** pane, ensure the **adventureworks** database is selected and the **products** table is listed.
3. In the **New query** pane, enter the following SQL code:

    ```sql
    SELECT ProductID, ProductName, Category
    FROM adventureworks.products; 
    ```

4. Use the **Run All** button to run the SQL code.
5. When the query has completed, review the table of results.
6. Use the **Save** button at the top right of the query editor to save the query as **Products and Categories**.

Saving a query makes it easy to retrieve the same data again at a later time.

## Create a dashboard

1. In the sidebar, select **(+) Create** and then select **Dashboard**.
2. In the **New dashboard** dialog box, enter the name **Adventure Works Products** and select **Save**.
3. In the **Adventure Works Products** dashboard, in the **Add** drop-down list, select **Visualization**.
4. In the **Add visualization widget** dialog box, select the **Products and Categories** query. Then select **Create new visualization**, set the title to **Products Per Category**. and select **Create visualization**.
5. In the visualization editor, set the following properties:
    - **Visualization type**: bar
    - **Horizontal chart**: selected
    - **Y column**: Category
    - **X columns**: Product ID : Count
    - **Group by**: Category
    - **Legend placement**: Automatic (Flexible)
    - **Legend items order**: Normal
    - **Stacking**: Stack
    - **Normalize values to percentage**: <u>Un</u>selected

6. Save the visualization and view it in the dashboard.
7. Select **Done editing** to view the dashboard as users will see it.

Dashboards are a great way to share data tables and visualizations with business users. You can schedule the dashboards to be refreshed periodically, and emailed to subscribers.

## Delete Azure Databricks resources

Now you've finished exploring SQL Warehouses in Azure Databricks, you must delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.

1. Close the Azure Databricks workspace browser tab and return to the Azure portal.
2. On the Azure portal, on the **Home** page, select **Resource groups**.
3. Select the resource group containing your Azure Databricks workspace (not the managed resource group).
4. At the top of the **Overview** page for your resource group, select **Delete resource group**.
5. Enter the resource group name to confirm you want to delete it, and select **Delete**.

    After a few minutes, your resource group and the managed workspace resource group associated with it will be deleted.
