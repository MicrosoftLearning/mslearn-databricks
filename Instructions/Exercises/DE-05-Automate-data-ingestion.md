---
lab:
    title: 'Automate data ingestion and processing using Azure Databricks'
---

# Automate data ingestion and processing using Azure Databricks

Databricks Jobs is a powerful service that allows for the automation of data ingestion and processing workflows. It enables the orchestration of complex data pipelines, which can include tasks like ingesting raw data from various sources, transforming this data using Delta Live Tables, and persisting it to Delta Lake for further analysis. With Azure Databricks, users can schedule and run their data processing tasks automatically, ensuring that data is always up-to-date and available for decision-making processes.

This lab will take approximately **20** minutes to complete.

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

7. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer. While you are waiting, review the [Schedule and orchestrate workflows](https://learn.microsoft.com/azure/databricks/jobs/) article in the Azure Databricks documentation.

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 13.3 LTS or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace)

1. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).

1. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

1. In the sidebar on the left, select the **(+) New** task, and then select **Cluster** (you may need to look in the **More** submenu).

1. In the **New Cluster** page, create a new cluster with the following settings:
    - **Cluster name**: *User Name's* cluster (the default cluster name)
    - **Policy**: Unrestricted
    - **Cluster mode**: Single Node
    - **Access mode**: Single user (*with your user account selected*)
    - **Databricks runtime version**: 13.3 LTS (Spark 3.4.1, Scala 2.12) or later
    - **Use Photon Acceleration**: Selected
    - **Node type**: Standard_D4ds_v5
    - **Terminate after** *20* **minutes of inactivity**

1. Wait for the cluster to be created. It may take a minute or two.

    > **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region. You can specify a region as a parameter for the setup script like this: `./mslearn-databricks/setup.ps1 eastus`

## Create a notebook and get source data

1. In the sidebar, use the **(+) New** link to create a **Notebook** and change the default notebook name (**Untitled Notebook *[date]***) to **Data Processing**. Then, in the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

2. In the first cell of the notebook, enter the following code, which uses *shell* commands to download data files from GitHub into the file system used by your cluster.

     ```python
    %sh
    rm -r /dbfs/FileStore
    mkdir /dbfs/FileStore
    wget -O /dbfs/FileStore/sample_sales_data.csv https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/sample_sales_data.csv
     ```

3. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.

## Automate data processing with Azure Databricks Jobs

1. Replace the code in the first of the notebook, with the following code. Then run it to load the data into a dataframe:

     ```python
    # Load the sample dataset into a DataFrame
    df = spark.read.csv('/FileStore/*.csv', header=True, inferSchema=True)
    df.show()
     ```

1. Move the mouse under the existing code cell, and use the **+ Code** icon that appears to add a new code cell. Then in the new cell, enter and run the following code to aggregate sales data by product category:

     ```python
    from pyspark.sql.functions import col, sum

    # Aggregate sales data by product category
    sales_by_category = df.groupBy('product_category').agg(sum('transaction_amount').alias('total_sales'))
    sales_by_category.show()
     ```

1. In the sidebar, use the **(+) New** link to create a **Job**.

1. Change the default job name (**New job *[date]***) to `Automated job`.

1. Configure the unnamed task in the job with the following settings:
    - **Task name**: `Run notebook`
    - **Type**: Notebook
    - **Source**: Workspace
    - **Path**: *Select your* Data Processing *notebook*
    - **Cluster**: *Select your cluster*

1. Select **Create task**.

1. Select **Run now**

    **Tip**: In the right-side panel, under **Schedule**, you can select **Add trigger** and set up a schedule for running the job (e.g., daily, weekly). However, for this exercise, we will execute it manually.

1. Select the **Runs** tab in the Job panel and monitor the job run.

1. After the job run is successful, you can select it in the **Runs** list and verify its output.

    You have successfully set up and automated data ingestion and processing using Azure Databricks Jobs. You can now scale this solution to handle more complex data pipelines and integrate with other Azure services for a robust data processing architecture.

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
