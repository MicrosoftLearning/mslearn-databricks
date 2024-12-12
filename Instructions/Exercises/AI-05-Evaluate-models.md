---
lab:
    title: 'Evaluate Large Language Models using Azure Databricks and Azure OpenAI'
---

# Evaluate Large Language Models using Azure Databricks and Azure OpenAI

Evaluating large language models (LLMs) involves a series of steps to ensure the model's performance meets the required standards. MLflow LLM Evaluate, a feature within Azure Databricks, provides a structured approach to this process, including setting up the environment, defining evaluation metrics, and analyzing results. This evaluation is crucial as LLMs often do not have a single ground truth for comparison, making traditional evaluation methods inadequate.

This lab will take approximately **20** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Provision an Azure OpenAI resource

If you don't already have one, provision an Azure OpenAI resource in your Azure subscription.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure OpenAI** resource with the following settings:
    - **Subscription**: *Select an Azure subscription that has been approved for access to the Azure OpenAI service*
    - **Resource group**: *Choose or create a resource group*
    - **Region**: *Make a **random** choice from any of the following regions*\*
        - East US 2
        - North Central US
        - Sweden Central
        - Switzerland West
    - **Name**: *A unique name of your choice*
    - **Pricing tier**: Standard S0

> \* Azure OpenAI resources are constrained by regional quotas. The listed regions include default quota for the model type(s) used in this exercise. Randomly choosing a region reduces the risk of a single region reaching its quota limit in scenarios where you are sharing a subscription with other users. In the event of a quota limit being reached later in the exercise, there's a possibility you may need to create another resource in a different region.

3. Wait for deployment to complete. Then go to the deployed Azure OpenAI resource in the Azure portal.

4. In the left pane, under **Resource Management**, select **Keys and Endpoint**.

5. Copy the endpoint and one of the available keys as you will use it later in this exercise.

## Deploy the required model

Azure provides a web-based portal named **Azure AI Studio**, that you can use to deploy, manage, and explore models. You'll start your exploration of Azure OpenAI by using Azure AI Studio to deploy a model.

> **Note**: As you use Azure AI Studio, message boxes suggesting tasks for you to perform may be displayed. You can close these and follow the steps in this exercise.

1. In the Azure portal, on the **Overview** page for your Azure OpenAI resource, scroll down to the **Get Started** section and select the button to go to **Azure AI Studio**.
   
1. In Azure AI Studio, in the pane on the left, select the **Deployments** page and view your existing model deployments. If you don't already have one, create a new deployment of the **gpt-35-turbo** model with the following settings:
    - **Deployment name**: *gpt-35-turbo*
    - **Model**: gpt-35-turbo
    - **Model version**: Default
    - **Deployment type**: Standard
    - **Tokens per minute rate limit**: 5K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled
    
> \* A rate limit of 5,000 tokens per minute is more than adequate to complete this exercise while leaving capacity for other people using the same subscription.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure Databricks** resource with the following settings:
    - **Subscription**: *Select the same Azure subscription that you used to create your Azure OpenAI resource*
    - **Resource group**: *The same resource group where you created your Azure OpenAI resource*
    - **Region**: *The same region where you created your Azure OpenAI resource*
    - **Name**: *A unique name of your choice*
    - **Pricing tier**: *Premium* or *Trial*

3. Select **Review + create** and wait for deployment to complete. Then go to the resource and launch the workspace.

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 13.3 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the resource group where the Azure Databricks workspace was created.
2. Select your Azure Databricks Service resource.
3. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

> **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

4. In the sidebar on the left, select the **(+) New** task, and then select **Cluster**.
5. In the **New Cluster** page, create a new cluster with the following settings:
    - **Cluster name**: *User Name's* cluster (the default cluster name)
    - **Policy**: Unrestricted
    - **Cluster mode**: Single Node
    - **Access mode**: Single user (*with your user account selected*)
    - **Databricks runtime version**: *Select the **<u>ML</u>** edition of the latest non-beta version of the runtime (**Not** a Standard runtime version) that:*
        - *Does **not** use a GPU*
        - *Includes Scala > **2.11***
        - *Includes Spark > **3.4***
    - **Use Photon Acceleration**: <u>Un</u>selected
    - **Node type**: Standard_D4ds_v5
    - **Terminate after** *20* **minutes of inactivity**

6. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Install required libraries

1. In your cluster's page, select the **Libraries** tab.

2. Select **Install New**.

3. Select **PyPI** as the library source and install `openai==1.42.0`.

## Create a new notebook

1. In the sidebar, use the **(+) New** link to create a **Notebook**.
   
1. Name your notebook and in the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

2. In the first cell of the notebook, run the following code with the access information you copied at the beginning of this exercise to assign persistent environment variables for authentication when using Azure OpenAI resources:

     ```python
    import os

    os.environ["AZURE_OPENAI_API_KEY"] = "your_openai_api_key"
    os.environ["AZURE_OPENAI_ENDPOINT"] = "your_openai_endpoint"
    os.environ["AZURE_OPENAI_API_VERSION"] = "2023-03-15-preview"
     ```

## Evaluate LLM with a custom function

In MLflow 2.8.0 and above, `mlflow.evaluate()` supports evaluating a Python function without requiring the model be logged to MLflow. The process involves specifying the model to evaluate, the metrics to compute, and the evaluation data, which is usually a Pandas DataFrame. 

1. In a new cell, run the following code to define a sample evaluation dataframe:

     ```python
    import pandas as pd

    eval_data = pd.DataFrame(
        {
            "inputs": [
                "What is MLflow?",
                "What is Spark?",
            ],
            "ground_truth": [
                "MLflow is an open-source platform for managing the end-to-end machine learning (ML) lifecycle. It was developed by Databricks, a company that specializes in big data and machine learning solutions. MLflow is designed to address the challenges that data scientists and machine learning engineers face when developing, training, and deploying machine learning models.",
                "Apache Spark is an open-source, distributed computing system designed for big data processing and analytics. It was developed in response to limitations of the Hadoop MapReduce computing model, offering improvements in speed and ease of use. Spark provides libraries for various tasks such as data ingestion, processing, and analysis through its components like Spark SQL for structured data, Spark Streaming for real-time data processing, and MLlib for machine learning tasks",
            ],
        }
    )
     ```

1. In a new cell, run the following code to initialize a client for your Azure OpenAI resource and define your customized function:

     ```python
    import os
    import pandas as pd
    from openai import AzureOpenAI

    client = AzureOpenAI(
        azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT"),
        api_key = os.getenv("AZURE_OPENAI_API_KEY"),
        api_version = os.getenv("AZURE_OPENAI_API_VERSION")
    )

    def openai_qa(inputs):
        answers = []
        system_prompt = "Please answer the following question in formal language."
        for index, row in inputs.iterrows():
            completion = client.chat.completions.create(
                model="gpt-35-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": "{row}"},
                ],
            )
            answers.append(completion.choices[0].message.content)

        return answers

     ```

1. In a new cell, run the following code to create an experiment and evaluate the custom function with the evaluation data:

     ```python
    import mlflow

    with mlflow.start_run() as run:
        results = mlflow.evaluate(
            openai_qa,
            eval_data,
            model_type="question-answering",
        )
     ```
Once the run has succeeded, it will generate a link to the experiment page where you can verify the model metrics. For `model_type="question-answering"`, the default metrics are **toxicity**, **ari_grade_level** and **flesch_kincaid_grade_level**.

## Clean up

When you're done with your Azure OpenAI resource, remember to delete the deployment or the entire resource in the **Azure portal** at `https://portal.azure.com`.

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
