---
lab:
  title: Implement LLMOps with Azure Databricks
  description: You'll gain hands-on experience implementing LLMOps practices by using MLflow to track and log LLM interactions, including parameters, metrics, predictions, and artifacts for each model run. You'll learn how to use MLflow's autologging capabilities and the Trace UI to monitor model performance over time, compare traces across different runs, and detect data drift to ensure your LLM applications remain reliable and performant in production.
  duration: 30 minutes
  level: 400
  islab: true
  primarytopics:
    - Azure Databricks
    - Azure Portal
    - Microsoft Foundry
---

# Implement LLMOps with Azure Databricks

LLMOps (Large Language Model Operations) brings structured observability to AI applications by tracking every interaction a model has in production. In this lab, you use Azure Databricks and Microsoft Foundry to connect a `gpt-4.1` model to MLflow's autologging capabilities, capturing inputs, outputs, token usage, and metadata for each run. After executing a prompt, you explore the MLflow Trace UI to see how individual requests are recorded — giving you the foundation to compare runs over time, detect data drift, and keep your LLM applications reliable at scale.

This lab will take approximately **30** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Create a Microsoft Foundry resource and project

If you don't already have one, create a Microsoft Foundry resource and project in your Azure subscription.

> **Note**: Creating a Foundry resource only requires a subscription, resource group, region, and name. No Key Vault or Application Insights resources are needed.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Use the following link to open the Foundry resource creation page: `https://portal.azure.com/#create/Microsoft.CognitiveServicesAIFoundry`
3. On the **Create** page, provide the following information on the **Basics** tab:
    - **Subscription**: *Select your Azure subscription*
    - **Resource group**: *Choose or create a resource group*
    - **Name**: *A unique name of your choice*
    - **Region**: *Make a **random** choice from any of the following regions*\*
        - North Central US
        - Sweden Central
    - **Default project name**: *Leave the pre-filled default or enter a custom project name*
4. Select **Review + create**, then select **Create** and wait for deployment to complete.

> \* Foundry resources are constrained by regional quotas. The listed regions include default quota for the model type(s) used in this exercise. Randomly choosing a region reduces the risk of a single region reaching its quota limit in scenarios where you are sharing a subscription with other users. In the event of a quota limit being reached later in the exercise, there's a possibility you may need to create another resource in a different region.

5. Once deployment completes, go to the deployed resource. In the left pane, under **Resource Management**, select **Keys and Endpoint**, then on the **Foundry** tab, copy the **API endpoint** — you will use it later in this exercise.

6. In the **Overview** page, select **Go to Foundry portal** to open your resource in the Foundry portal (or navigate directly to `https://ai.azure.com`).

7. In **Microsoft Foundry**, select the project within your Foundry resource. A default project is created automatically — select it to open it. If no project exists, create one:
    - Select **+ New project** in the left navigation.
    - Enter a **Project name** and select **Create project**.
    - Wait for the project to be created.

8. In a new browser tab, return to the **Azure portal** at `https://portal.azure.com` and launch Cloud Shell. Run the following command to get a temporary authorization token for API calls. Copy the `accessToken` value and save it alongside the endpoint you copied in step 5.

    ```bash
    az account get-access-token --resource https://cognitiveservices.azure.com
    ```

    >**Note**: You only need to copy the `accessToken` field value and **not** the entire JSON output.

## Deploy the required model

Microsoft Foundry allows you to deploy, manage, and explore models.

> **Note**: As you use Microsoft Foundry, message boxes suggesting tasks for you to perform may be displayed. You can close these and follow the steps in this exercise.

1. In **Microsoft Foundry**, on the home page select **View deployments** (or select **Build** in the top navigation bar, then select **Deployments**).

1. Select **Deploy** > **Deploy a base model**, search for and select **gpt-4.1**, then select **Deploy** > **Custom settings** to configure the deployment with the following settings:
    - **Deployment name**: *gpt-4.1*
    - **Deployment type**: Global Standard
    - **Model version** *(under Model version settings)*: *2025-04-14*
    - **Model version upgrade policy** *(under Model version settings)*: Upgrade once new default version becomes available
    - **Tokens per minute rate limit**: 10K\*
    - **Guardrails**: DefaultV2

    Then select **Deploy** at the bottom of the page.

> \* A rate limit of 10,000 tokens per minute is more than adequate to complete this exercise while leaving capacity for other people using the same subscription.

2. Wait for the deployment to complete.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure Databricks** resource with the following settings:
    - **Subscription**: *Select the same Azure subscription that you used to create your Foundry resource*
    - **Resource group**: *The same resource group where you created your Foundry resource*
    - **Workspace name**: *A unique name of your choice*
    - **Region**: *Select any available region*
    - **Pricing tier**: Premium (+ Role-based access controls)
    - **Workspace type**: Hybrid
    - **Managed Resource Group name**: *Leave blank*

> **Note**: Azure Databricks does not need to be in the same region as your Foundry resource. If cluster creation fails due to quota limits in your chosen region, try deleting the workspace and creating a new one in a different region.

1. Select **Review + create**, and once validation succeeds, select **Create**.

1. When deployment is complete, select **Go to resource**, then select **Launch Workspace** to open your Azure Databricks workspace in a new browser tab.

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 17.3 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the sidebar on the left, select the **(+) New** task, select **More**, and then select **Cluster**.
1. In the **New Cluster** page, create a new cluster with the following settings:
    - **Cluster name**: *User Name's* cluster (the default cluster name)
    - **Policy**: Unrestricted
    - **Machine learning**: Enabled
    - **Databricks runtime**: 17.3 LTS
    - **Use Photon Acceleration**: <u>Un</u>selected
    - **Worker type**: Standard_D4ds_v5
    - **Single node**: Checked
    - **Terminate after**: 30 minutes of inactivity
1. Select **Create**

1. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Create a notebook

1. In the sidebar on the left, use the **(+) New** link to create a **Notebook**.

1. Name your notebook and select `Python` as the language. In the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

1. In the first code cell, enter and run the following code to install the required libraries:
   
    ```python
   %pip install openai mlflow
    ```

    > **Note**: You may see warnings that package versions are not pinned, or that core Python package versions changed. These are advisory only and won't affect the lab — the `%restart_python` command in the next step restarts the Python environment to apply the updates.

1. After the installation is complete, restart the kernel in a new cell:

    ```python
   %restart_python
    ```

## Log the LLM using MLflow

In this section, you wire up MLflow's autologging before making any API calls. Calling `mlflow.openai.autolog()` tells MLflow to intercept every OpenAI SDK call and automatically record the prompt, response, model name, and token counts as a trace. You then wrap a test prompt inside `mlflow.start_run()` so it belongs to a named experiment run, and manually log one extra parameter — the number of completion tokens — to show how you can attach custom metrics alongside the automatic trace data.

1. In a new cell, run the following code with the access information you copied earlier to assign persistent environment variables for authentication:

     ```python
    import os

    os.environ["AZURE_OPENAI_ENDPOINT"] = "your_foundry_endpoint"
    os.environ["COGNITIVE_SERVICES_TOKEN"] = "your_cognitiveservices_access_token"  # from: az account get-access-token --resource https://cognitiveservices.azure.com
     ```

    > **Note**: The access token expires after approximately 60 minutes. If you encounter authentication errors during the lab, re-run the Cloud Shell command and update this cell.
1. In a new cell, run the following code to initialize your Azure OpenAI client:

     ```python
    import os
    from openai import AzureOpenAI

    client = AzureOpenAI(
       azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT"),
       azure_ad_token = os.getenv("COGNITIVE_SERVICES_TOKEN"),
       api_version = "2025-04-01-preview"
    )
     ```

1. In a new cell, run the following code to initialize MLflow tracking and log the model:     

     ```python
    import mlflow
    from openai import AzureOpenAI

    system_prompt = "Assistant is a large language model trained by OpenAI."

    mlflow.openai.autolog()

    with mlflow.start_run():

        response = client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": "Tell me a joke about animals."},
            ],
        )

        print(response.choices[0].message.content)
        mlflow.log_param("completion_tokens", response.usage.completion_tokens)
    mlflow.end_run()
     ```

The cell above will start an experiment in your workspace and register the traces of each chat completion iteration, keeping track of the inputs, outputs and metadata of each run.

## Monitor the model

After running the last cell, the trace is recorded automatically. To view it:

1. In the left sidebar, select **Experiments**.
1. In the list of experiments, select the name of your notebook experiment (for example, *New Notebook 2026-06-25 17:27:57*).
1. In the left panel of the experiment view, under **Observability**, select **Traces**.

You'll see a table listing each recorded trace with columns for the **Request** (the prompt you sent), **Response** (the model's reply), **Tokens** used, **Execution time**, and **State**. Select any trace to expand it and see the full input/output detail.

With autologging active, every run you add builds a history you can compare. Look at how the prompt, response content, and token counts vary across runs. You can also attach custom metrics using `mlflow.log_param()`. Over time, drift shows up as systematic shifts — responses getting longer or shorter, token usage climbing, or output quality changing — and spotting these trends early lets you retune the model or adjust the prompt before users notice a difference.

## Clean up

When you're done with your Microsoft Foundry resource, remember to delete the deployment or the entire resource in the **Azure portal** at `https://portal.azure.com`.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
