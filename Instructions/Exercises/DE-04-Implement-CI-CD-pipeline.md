---
lab:
    title: 'Implement CI/CD workflows with Azure Databricks'
---

# Implement CI/CD workflows with Azure Databricks

Implementing CI/CD workflows with GitHub Actions and Azure Databricks can streamline your development process and enhance automation. GitHub Actions provide a powerful platform for automating software workflows, including continuous integration (CI) and continuous delivery (CD). When integrated with Azure Databricks, these workflows can execute complex data tasks, like running notebooks or deploying updates to Databricks environments. For instance, you can use GitHub Actions to automate the deployment of Databricks notebooks, manage Databricks file system uploads, and set up the Databricks CLI within your workflows. This integration facilitates a more efficient and error-resistant development cycle, especially for data-driven applications.

This lab will take approximately **40** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

>**Note:** You need a Github account to complete this exercise.

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
    - **Node type**: Standard_D4ds_v5
    - **Terminate after** *20* **minutes of inactivity**

1. Wait for the cluster to be created. It may take a minute or two.

    > **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region. You can specify a region as a parameter for the setup script like this: `./mslearn-databricks/setup.ps1 eastus`

## Create a notebook and ingest data

1. In the sidebar, use the **(+) New** link to create a **Notebook**. In the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

2. In the first cell of the notebook, enter the following code, which uses *shell* commands to download data files from GitHub into the file system used by your cluster.

     ```python
    %sh
    rm -r /dbfs/FileStore
    mkdir /dbfs/FileStore
    wget -O /dbfs/FileStore/sample_sales.csv https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/sample_sales.csv
     ```

3. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.
   
## Set up a GitHub repository

Once you connect a GitHub repository to an Azure Databricks workspace, you can set up CI/CD pipelines in GitHub Actions that trigger with any changes made to your repository.

1. Go to your [GitHub account](https://github.com/) and create a new repository for your project.

2. Clone the repository to your local machine using `git clone`.

3. Download the required files for this exercise to your local repository:
   - [CSV file](https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/sample_sales.csv)
   - [Databricks notebook](https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/sample_sales_notebook.dbc)
   - [Job configuration file](https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/job-config.json)

   Commit and push the changes.

## Set up repository secrets

Secrets are variables that you create in an organization, repository, or repository environment. The secrets that you create are available to use in GitHub Actions workflows. GitHub Actions can only read a secret if you explicitly include the secret in a workflow.

As GitHub Actions workflows need to access resources from Azure Databricks, authentication credentials will be stored as encrypted variables to be used with the CI/CD pipelines.

Before creating repository secrets, you need to generate a personal access token in Azure Databricks:

1. In your Azure Databricks workspace, select your Azure Databricks username in the top bar, and then select **Settings** from the drop down.

2. Select **Developer**.

3. Next to **Access tokens**, select **Manage**.

4. Select **Generate new token** and then select **Generate**.

5. Copy the displayed token to a secure location, and then select **Done**.

6. Now in your repository page, select the **Settings** tab.

   ![GitHub settings tab](./images/github-settings.png)

7. In the left sidebar, select **Secrets and variables** and then select **Actions**.

8. Select **New repository secret** and add each of these variables:
   - **Name:** DATABRICKS_HOST **Secret:** Add the URL of your Databricks workspace.
   - **Name:** DATABRICKS_TOKEN **Secret:** Add the access token generated previously.

## Set up CI/CD pipelines

Now that you have stored the necessary variables for accessing your Azure Databricks workspace from GitHub, you will create workflows to automate data ingestion and processing, which will trigger every time the repository is updated.

1. In your repository page, select the **Actions** tab.

    ![GitHub Actions tab](./images/github-actions.png)

2. Select **set up a workflow yourself** and enter the following code:

     ```yaml
    name: CI Pipeline for Azure Databricks

    on:
      push:
        branches:
          - main
      pull_request:
        branches:
          - main

    jobs:
      deploy:
        runs-on: ubuntu-latest

        steps:
        - name: Checkout code
          uses: actions/checkout@v3

        - name: Set up Python
          uses: actions/setup-python@v4
          with:
            python-version: '3.x'

        - name: Install Databricks CLI
          run: |
            pip install databricks-cli

        - name: Configure Databricks CLI
          run: |
            databricks configure --token <<EOF
            ${{ secrets.DATABRICKS_HOST }}
            ${{ secrets.DATABRICKS_TOKEN }}
            EOF

        - name: Download Sample Data from DBFS
          run: databricks fs cp dbfs:/FileStore/sample_sales.csv . --overwrite
     ```

This code will install and configure Databricks CLI, and download the sample data to your repository every time a commit is pushed or a pull request is merged.

3. Name the workflow **CI pipeline** and select **Commit changes**. The pipeline will run automatically and you can check its status in the **Actions** tab.

Once the workflow is completed, it is time to setup the configurations for your CD pipeline.

4. Go to your workspace page, select **Compute** and then select your cluster.

5. In the cluster's page, select **More ...** and then select **View JSON**. Copy the cluster's id.

6. Open the `job-config.json` in your repository and replace `your_cluster_id` with the cluster's id you just copied. Also replace `/Workspace/Users/your_username/your_notebook` with the path in your workspace where you want to store the notebook used in the pipeline. Commit the changes.

> **Note:** If you go to the **Actions** tab, you will see that the CI pipeline started running again. Since it is supposed to trigger whenever a commit is pushed, changing `job-config.json` will deploy the pipeline as expected.

7. In the **Actions** tab, create a new workflow named **CD pipeline** and enter the following code:

     ```yaml
    name: CD Pipeline for Azure Databricks

    on:
      push:
        branches:
          - main

    jobs:
      deploy:
        runs-on: ubuntu-latest

        steps:
        - name: Checkout code
          uses: actions/checkout@v3

        - name: Set up Python
          uses: actions/setup-python@v4
          with:
            python-version: '3.x'

        - name: Install Databricks CLI
          run: pip install databricks-cli

        - name: Configure Databricks CLI
          run: |
            databricks configure --token <<EOF
            ${{ secrets.DATABRICKS_HOST }}
            ${{ secrets.DATABRICKS_TOKEN }}
            EOF
        - name: Upload Notebook to DBFS
          run: databricks fs cp /path/to/your/notebook /Workspace/Users/your_username/your_notebook --overwrite
          env:
            DATABRICKS_TOKEN: ${{ secrets.DATABRICKS_TOKEN }}

        - name: Run Databricks Job
          run: |
            databricks jobs create --json-file job-config.json
            databricks jobs run-now --job-id $(databricks jobs list | grep 'CD pipeline' | awk '{print $1}')
          env:
            DATABRICKS_TOKEN: ${{ secrets.DATABRICKS_TOKEN }}
     ```

Before committing the changes, replace `/path/to/your/notebook` with the file path of your notebook in your repository and `/Workspace/Users/your_username/your_notebook` with the file path where you want to import the notebook in your Azure Databricks workspace.

This code will once again install and configure Databricks CLI, import the Notebook to your Databricks File System, and create and run a job that you can monitor in the **Workflows** page of your workspace. Check the output and verify that the data sample is modified.

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
