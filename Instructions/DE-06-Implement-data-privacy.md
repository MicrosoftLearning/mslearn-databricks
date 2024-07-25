---
lab:
    title: 'Implementing Data Privacy and Governance using Microsoft Purview and Unity Catalog with Azure Databricks'
---

# Implementing Data Privacy and Governance using Microsoft Purview and Unity Catalog with Azure Databricks

Microsoft Purview allows for comprehensive data governance across your entire data estate, integrating seamlessly with Azure Databricks to manage Lakehouse data and bring metadata into the Data Map. Unity Catalog enhances this by providing centralized data management and governance, simplifying security and compliance across Databricks workspaces.

This lab will take approximately **30** minutes to complete.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

This exercise includes a script to provision a new Azure Databricks workspace. The script attempts to create a *Premium* tier Azure Databricks workspace resource in a region in which your Azure subscription has sufficient quota for the compute cores required in this exercise; and assumes your user account has sufficient permissions in the subscription to create an Azure Databricks workspace resource. If the script fails due to insufficient quota or permissions, you can try to [create an Azure Databricks workspace interactively in the Azure portal](https://learn.microsoft.com/azure/databricks/getting-started/#--create-an-azure-databricks-workspace).

1. In a web browser, sign into the [Azure portal](https://portal.azure.com) at `https://portal.azure.com`.

2. Use the **[\>_]** button to the right of the search bar at the top of the page to create a new Cloud Shell in the Azure portal, selecting a ***PowerShell*** environment and creating storage if prompted. The cloud shell provides a command line interface in a pane at the bottom of the Azure portal, as shown here:

    ![Azure portal with a cloud shell pane](./images/cloud-shell.png)

    > **Note**: If you have previously created a cloud shell that uses a *Bash* environment, use the the drop-down menu at the top left of the cloud shell pane to change it to ***PowerShell***.

3. Note that you can resize the cloud shell by dragging the separator bar at the top of the pane, or by using the **&#8212;**, **&#9723;**, and **X** icons at the top right of the pane to minimize, maximize, and close the pane. For more information about using the Azure Cloud Shell, see the [Azure Cloud Shell documentation](https://docs.microsoft.com/azure/cloud-shell/overview).

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

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 13.3 LTS or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace)

1. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).

1. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

1. In the sidebar on the left, select the **(+) New** task, and then select **Cluster**.

1. In the **New Cluster** page, create a new cluster with the following settings:
    - **Cluster name**: *User Name's* cluster (the default cluster name)
    - **Policy**: Unrestricted
    - **Cluster mode**: Single Node
    - **Access mode**: Single user (*with your user account selected*)
    - **Databricks runtime version**: 13.3 LTS (Spark 3.4.1, Scala 2.12) or later
    - **Use Photon Acceleration**: Selected
    - **Node type**: Standard_DS3_v2
    - **Terminate after** *20* **minutes of inactivity**

1. Wait for the cluster to be created. It may take a minute or two.

    > **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region. You can specify a region as a parameter for the setup script like this: `./mslearn-databricks/setup.ps1 eastus`

## Set up Unity Catalog

Unity Catalog metastores register metadata about securable objects (such as tables, volumes, external locations, and shares) and the permissions that govern access to them. Each metastore exposes a three-level namespace (`catalog`.`schema`.`table`) by which data can be organized. You must have one metastore for each region in which your organization operates. To work with Unity Catalog, users must be on a workspace that is attached to a metastore in their region.

1. In the sidebar, select **Catalog**.

2. In the Catalog explorer, a default Unity Catalog with your workspace name (**databricks-*xxxxxxx*** if you used the setup script to create it) should be present. Select the catalog, then at the top of the right pane select **Create schema**.

3. Name the new schema **ecommerce**, choose the storage location created with your workspace, and select **Create**.

4. Select your catalog and in the right pane select the **Workspaces** tab. Verify that your workspace has `Read & Write` access to it.

## Ingest sample data into Azure Databricks

1. At the top of the catalog explorer, select **+** and then select **Add data**.

- Use the Databricks interface to upload customers.csv, sales.csv, and products.csv to the DBFS (Databricks File System).

2. Create Tables from CSV Files

```python
# Load Customer Data
customers_df = spark.read.format("csv").option("header", "true").load("/dbfs/FileStore/customers.csv")
customers_df.write.saveAsTable("ecommerce.customers")

# Load Sales Data
sales_df = spark.read.format("csv").option("header", "true").load("/dbfs/FileStore/sales.csv")
sales_df.write.saveAsTable("ecommerce.sales")

# Load Product Data
products_df = spark.read.format("csv").option("header", "true").load("/dbfs/FileStore/products.csv")
products_df.write.saveAsTable("ecommerce.products")
```

### Step 3: Set Up Microsoft Purview

1. Create a Microsoft Purview Account

- Navigate to the Azure portal.
- Click on "Create a resource" and search for "Microsoft Purview".
- Click "Create" and fill in the necessary details to create a Purview account.

2. Connect Azure Databricks with Microsoft Purview

- In the Purview portal, navigate to the "Data Map" section.
- Click "Register" to register your Azure Databricks as a data source.
- Provide the necessary connection details and credentials.

### Step 4: Implement Data Privacy and Governance Policies
1. Create Classifications in Microsoft Purview

- In the Purview portal, go to the "Classifications" section.
- Create classifications such as "PII" (Personally Identifiable Information).

2. Apply Classifications to Data Assets
- Navigate to the "Data Catalog" in Purview.
- Locate the Databricks tables and apply the relevant classifications (e.g., classify the email and phone columns in the customers table as PII).

3. Set Up Data Policies in Unity Catalog

- Go to Unity Catalog in Databricks.
- Create a data access policy to restrict access to PII data.

```sql
CREATE OR REPLACE TABLE ecommerce.customers (
  customer_id STRING,
  name STRING,
  email STRING,
  phone STRING,
  address STRING,
  city STRING,
  state STRING,
  zip_code STRING,
  country STRING
) TBLPROPERTIES ('data_classification'='PII');

GRANT SELECT ON TABLE ecommerce.customers TO ROLE data_scientist;
REVOKE SELECT (email, phone) ON TABLE ecommerce.customers FROM ROLE data_scientist;
```

### Step 5: Monitor and Audit Data Access
1. Set Up Monitoring in Microsoft Purview

- In Purview, navigate to the "Insights" section.
- Set up monitoring to track data access and usage.

2. Audit Data Access in Databricks

- Use Databricks audit logs to monitor access to sensitive data.
- Enable diagnostic logging in Databricks and integrate with Azure Monitor for centralized logging and alerting.

### Step 6: Validate Data Privacy and Governance
1. Test Data Access Restrictions

- Attempt to query the customers table as a user with the data_scientist role.
- Verify that access to PII columns (email and phone) is restricted.

2. Review Audit Logs and Insights

- Check Purview insights for data access patterns.
- Review Databricks audit logs to ensure compliance with data privacy policies.

By following these steps, you have successfully implemented data privacy and governance using Microsoft Purview and Unity Catalog with Azure Databricks. This lab has equipped you with the knowledge to manage and govern data assets, enforce data privacy policies, and monitor data usage effectively.
