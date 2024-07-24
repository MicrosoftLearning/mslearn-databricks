---
lab:
    title: 'Implement CI/CD Pipelines with Azure Databricks and Azure DevOps or Azure Databricks and GitHub'
---

# Implement CI/CD Pipelines with Azure Databricks and Azure DevOps or Azure Databricks and GitHub

Implementing Continuous Integration (CI) and Continuous Deployment (CD) pipelines with Azure Databricks and Azure DevOps or Azure Databricks and GitHub involves setting up a series of automated steps to ensure that code changes are integrated, tested, and deployed efficiently. The process typically includes connecting to a Git repository, running jobs using Azure Pipelines to build and unit test code, and deploying the build artifacts for use in Databricks notebooks. This workflow enables a robust development cycle, allowing for continuous integration and delivery that aligns with modern DevOps practices.

This lab will take approximately **30** minutes to complete.

>**Note:** You need a Github account and Azure DevOps access to complete this exercise.

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

## Create a notebook and ingest data

1. In the sidebar, use the **(+) New** link to create a **Notebook**. In the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

2. In the first cell of the notebook, enter the following code, which uses *shell* commands to download data files from GitHub into the file system used by your cluster.

     ```python
    %sh
    rm -r /dbfs/sample_data
    mkdir /dbfs/sample_data
    wget -O /dbfs/sample_data/sample_sales.csv https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/sample_sales.csv
     ```

3. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.
   
## Set up a GitHub repository and Azure DevOps project

1. Go to your [GitHub account](https://github.com/) and create a new repository for your project.

2. Clone the repository to your local machine using `git clone`.

3. Add the sample CSV file to your repository and commit the changes.

4. Create a basic Databricks notebook:
- Create a new notebook in your repository with some basic data processing code, such as reading the CSV file and performing some transformations.

#### Step 3: Set Up Azure DevOps
1. Create an Azure DevOps project:
- Go to the Azure DevOps portal and create a new project.

2. Connect Azure DevOps to GitHub:
- In your Azure DevOps project, go to the "Repos" section and connect it to your GitHub repository.

3. Create a Service Connection:

- In Azure DevOps, navigate to "Project settings" > "Service connections".
- Create a new service connection for Azure, granting access to your Databricks workspace.

#### Step 4: Configure CI Pipeline in Azure DevOps
1. Create a new pipeline:

- In your Azure DevOps project, go to the "Pipelines" section and create a new pipeline.
- Choose "GitHub" as the source and select your repository.

2. Define the CI pipeline:

- Use the following YAML configuration for the CI pipeline:

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.x'
    addToPath: true

- script: |
    pip install databricks-cli
  displayName: 'Install Databricks CLI'

- script: |
    databricks fs cp dbfs:/FileStore/sample_sales.csv .
  displayName: 'Download Sample Data from DBFS'

- script: |
    python -m unittest discover -s tests
  displayName: 'Run Unit Tests'
```

#### Step 5: Configure CD Pipeline in Azure DevOps
1. Create a new release pipeline:
- In your Azure DevOps project, go to the "Pipelines" > "Releases" section and create a new release pipeline.

2. Add an artifact:
- Select your build pipeline as the artifact source.

3. Define the CD pipeline:
- Add a stage and configure the tasks to deploy to Azure Databricks.

```yaml
stages:
- stage: Deploy
  jobs:
  - job: DeployToDatabricks
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.x'
        addToPath: true

    - script: |
        pip install databricks-cli
      displayName: 'Install Databricks CLI'

    - script: |
        databricks workspace import_dir /path/to/notebooks /Workspace/Notebooks
      displayName: 'Deploy Notebooks to Databricks'
```

#### Step 6: Run the Pipelines
1. Commit and push changes:

- Commit and push your changes to the GitHub repository.

2. Trigger the CI pipeline:

- The CI pipeline will automatically run when changes are pushed to the repository.
- Verify that the CI pipeline completes successfully.

3. Trigger the CD pipeline:

- Create a new release in the release pipeline and deploy the notebooks to Databricks.
- Verify that the notebooks are deployed and executed successfully in your Databricks workspace.

### Conclusion
You've successfully set up CI/CD pipelines using Azure DevOps and GitHub, integrating with Azure Databricks to automate the deployment of your data engineering solutions. This lab provides a foundational understanding of how to leverage these tools to streamline your development and deployment processes.







