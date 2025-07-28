---
lab:
    title: 'Fine-Tuning Large Language Models using Azure Databricks and Azure OpenAI'
---

# Fine-Tuning Large Language Models using Azure Databricks and Azure OpenAI

With Azure Databricks, users can now leverage the power of LLMs for specialized tasks by fine-tuning them with their own data, enhancing domain-specific performance. To fine-tune a language model using Azure Databricks, you can utilize the Mosaic AI Model Training interface which simplifies the process of full model fine-tuning. This feature allows you to fine-tune a model with your custom data, with checkpoints saved to MLflow, ensuring you retain complete control over the fine-tuned model.

This lab will take approximately **60** minutes to complete.

> **NOTE**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

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

6. Launch Cloud Shell and run `az account get-access-token` to get a temporary authorization token for API testing. Keep it together with the endpoint and key copied previously.

    >**NOTE**: You only need to copy the `accessToken` field value and **not** the entire JSON output.

## Deploy the required model

Azure provides a web-based portal named **Azure AI Foundry**, that you can use to deploy, manage, and explore models. You'll start your exploration of Azure OpenAI by using Azure AI Foundry to deploy a model.

> **NOTE**: As you use Azure AI Foundry, message boxes suggesting tasks for you to perform may be displayed. You can close these and follow the steps in this exercise.

1. In the Azure portal, on the **Overview** page for your Azure OpenAI resource, scroll down to the **Get Started** section and select the button to go to **Azure AI Foundry**.
   
1. In Azure AI Foundry, in the pane on the left, select the **Deployments** page and view your existing model deployments. If you don't already have one, create a new deployment of the **gpt-4o** model with the following settings:
    - **Deployment name**: *gpt-4o*
    - **Deployment type**: Standard
    - **Model version**: *Use default version*
    - **Tokens per minute rate limit**: 10K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled
    
> \* A rate limit of 10,000 tokens per minute is more than adequate to complete this exercise while leaving capacity for other people using the same subscription.

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

> **Tip**: If you already have a cluster with a 16.4 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the resource group where the Azure Databricks workspace was created.
2. Select your Azure Databricks Service resource.
3. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

> **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

4. In the sidebar on the left, select the **(+) New** task, and then select **Cluster**.
5. In the **New Cluster** page, create a new cluster with the following settings:
    - **Cluster name**: *User Name's* cluster (the default cluster name)
    - **Policy**: Unrestricted
    - **Machine learning**: Enabled
    - **Databricks runtime**: 16.4 LTS
    - **Use Photon Acceleration**: <u>Un</u>selected
    - **Worker type**: Standard_D4ds_v5
    - **Single node**: Checked

6. Wait for the cluster to be created. It may take a minute or two.

> **NOTE**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Create a new notebook and ingest data

1. In the sidebar, use the **(+) New** link to create a **Notebook**. In the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.
1. In a new browser tab, download the [training dataset](https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/training_set.jsonl) at `https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/training_set.jsonl` and the [validation dataset](https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/validation_set.jsonl) at `https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/validation_set.jsonl` that will be used in this exercise.

> **Note**: Your device might default to saving the file as a .txt file. In the **Save as type** field, select **All files** and remove the .txt suffix to ensure you're saving the file as JSONL.

1. Back in the Databricks workspace tab, with your notebook open, select the **Catalog (CTRL + Alt + C)** explorer and select the ➕ icon to **Add data**.
1. In the **Add data** page, select **Upload files to DBFS**.
1. In the **DBFS** page, name the target directory `fine_tuning` and upload the .jsonl files you saved earlier.
1. In the sidebar, select **Workspace** and open your notebook again.
1. In the first cell of the notebook, enter the following code with the access information you copied at the beginning of this exercise to assign persistent environment variables for authentication when using Azure OpenAI resources:

    ```python
   import os

   os.environ["AZURE_OPENAI_API_KEY"] = "your_openai_api_key"
   os.environ["AZURE_OPENAI_ENDPOINT"] = "your_openai_endpoint"
   os.environ["TEMP_AUTH_TOKEN"] = "your_access_token"
    ```

1. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.
     
## Validate token counts

Both `training_set.jsonl` and `validation_set.jsonl` are made of different conversation examples between `user` and `assistant` that will serve as data points for training and validating the fine-tuned model. While the datasets for this exercise are considered small, it is important to keep in mind when working with bigger datasets that the LLMs have a maximum context length in terms of tokens. Therefore, you can verify the token count of your datasets before training your model and revise them if necessary. 

1. In a new cell, run the following code to validate the token counts for each file:

    ```python
   import json
   import tiktoken
   import numpy as np
   from collections import defaultdict

   encoding = tiktoken.get_encoding("cl100k_base")

   def num_tokens_from_messages(messages, tokens_per_message=3, tokens_per_name=1):
       num_tokens = 0
       for message in messages:
           num_tokens += tokens_per_message
           for key, value in message.items():
               num_tokens += len(encoding.encode(value))
               if key == "name":
                   num_tokens += tokens_per_name
       num_tokens += 3
       return num_tokens

   def num_assistant_tokens_from_messages(messages):
       num_tokens = 0
       for message in messages:
           if message["role"] == "assistant":
               num_tokens += len(encoding.encode(message["content"]))
       return num_tokens

   def print_distribution(values, name):
       print(f"\n##### Distribution of {name}:")
       print(f"min / max: {min(values)}, {max(values)}")
       print(f"mean / median: {np.mean(values)}, {np.median(values)}")

   files = ['/dbfs/FileStore/tables/fine_tuning/training_set.jsonl', '/dbfs/FileStore/tables/fine_tuning/validation_set.jsonl']

   for file in files:
       print(f"File: {file}")
       with open(file, 'r', encoding='utf-8') as f:
           dataset = [json.loads(line) for line in f]

       total_tokens = []
       assistant_tokens = []

       for ex in dataset:
           messages = ex.get("messages", {})
           total_tokens.append(num_tokens_from_messages(messages))
           assistant_tokens.append(num_assistant_tokens_from_messages(messages))

       print_distribution(total_tokens, "total tokens")
       print_distribution(assistant_tokens, "assistant tokens")
       print('*' * 75)
    ```

As a reference, the model used in this exercise, GPT-4o, has the context limit (total number of tokens in the input prompt and the generated response combined) of 128K tokens.

## Upload fine-tuning files to Azure OpenAI

Before you start to fine-tune the model, you need to initialize an OpenAI client and add the fine-tuning files to its environment, generating file IDs that will be used to initialize the job.

1. In a new cell, run the following code:

     ```python
    import os
    from openai import AzureOpenAI

    client = AzureOpenAI(
      azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT"),
      api_key = os.getenv("AZURE_OPENAI_API_KEY"),
      api_version = "2024-05-01-preview"  # This API version or later is required to access seed/events/checkpoint features
    )

    training_file_name = '/dbfs/FileStore/tables/fine_tuning/training_set.jsonl'
    validation_file_name = '/dbfs/FileStore/tables/fine_tuning/validation_set.jsonl'

    training_response = client.files.create(
        file = open(training_file_name, "rb"), purpose="fine-tune"
    )
    training_file_id = training_response.id

    validation_response = client.files.create(
        file = open(validation_file_name, "rb"), purpose="fine-tune"
    )
    validation_file_id = validation_response.id

    print("Training file ID:", training_file_id)
    print("Validation file ID:", validation_file_id)
     ```

## Submit fine-tuning job

Now that the fine-tuning files have been successfully uploaded you can submit your fine-tuning training job. It isn't unusual for training to take more than an hour to complete. Once training is completed, you can see the results in Azure AI Foundry by selecting the **Fine-tuning** option in the left pane.

1. In a new cell, run the following code to start the fine-tuning training job:

    ```python
   response = client.fine_tuning.jobs.create(
       training_file = training_file_id,
       validation_file = validation_file_id,
       model = "gpt-4o",
       seed = 105 # seed parameter controls reproducibility of the fine-tuning job. If no seed is specified one will be generated automatically.
   )

   job_id = response.id
    ```

The `seed` parameter controls reproducibility of the fine-tuning job. Passing in the same seed and job parameters should produce the same results, but can differ in rare cases. If no seed is specified one will be generated automatically.

2. In a new cell, you can run the following code to monitor the status of the fine-tuning job:

    ```python
   print("Job ID:", response.id)
   print("Status:", response.status)
    ```

    >**NOTE**: You can also monitor the job status in AI Foundry by selecting **Fine-tuning** in the left sidebar.

3. Once the job status changes to `succeeded`, run the following code to get the final results:

    ```python
   response = client.fine_tuning.jobs.retrieve(job_id)

   print(response.model_dump_json(indent=2))
   fine_tuned_model = response.fine_tuned_model
    ```

4. Review the json response and note the unique name generated in the `"fine_tuned_model"` field. It will be used in the following optional task.

    >**NOTE**: Fine-tuning a model can take over 60 minutes, so you can finish the exercise at this point and consider the model's deployment an optional task in case you have time to spare.

## [OPTIONAL] Deploy fine-tuned model

Now that you have a fine-tuned model, you can deploy it as a customized model and use it like any other deployed model in either the **Chat** Playground of Azure AI Foundry, or via the chat completion API.

1. In a new cell, run the following code to deploy your fine-tuned model, replacing the placeholders `<YOUR_SUBSCRIPTION_ID>`, `<YOUR_RESOURCE_GROUP_NAME>`, `<YOUR_AZURE_OPENAI_RESOURCE_NAME>`, and `<FINE_TUNED_MODEL>`:
   
    ```python
   import json
   import requests

   token = os.getenv("TEMP_AUTH_TOKEN")
   subscription = "<YOUR_SUBSCRIPTION_ID>"
   resource_group = "<YOUR_RESOURCE_GROUP_NAME>"
   resource_name = "<YOUR_AZURE_OPENAI_RESOURCE_NAME>"
   model_deployment_name = "gpt-4o-ft"

   deploy_params = {'api-version': "2023-05-01"}
   deploy_headers = {'Authorization': 'Bearer {}'.format(token), 'Content-Type': 'application/json'}

   deploy_data = {
       "sku": {"name": "standard", "capacity": 1},
       "properties": {
           "model": {
               "format": "OpenAI",
               "name": "<FINE_TUNED_MODEL>",
               "version": "1"
           }
       }
   }
   deploy_data = json.dumps(deploy_data)

   request_url = f'https://management.azure.com/subscriptions/{subscription}/resourceGroups/{resource_group}/providers/Microsoft.CognitiveServices/accounts/{resource_name}/deployments/{model_deployment_name}'

   print('Creating a new deployment...')

   r = requests.put(request_url, params=deploy_params, headers=deploy_headers, data=deploy_data)

   print(r)
   print(r.reason)
   print(r.json())
    ```

> **NOTE**: You can find your subscription ID in the Overview page of your Databricks workspace or OpenAI resource on Azure Portal.

2. In a new cell, run the following code to use your customized model in a chat completion call:
   
    ```python
   import os
   from openai import AzureOpenAI

   client = AzureOpenAI(
     azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT"),
     api_key = os.getenv("AZURE_OPENAI_API_KEY"),
     api_version = "2024-02-01"
   )

   response = client.chat.completions.create(
       model = "gpt-4o-ft",
       messages = [
           {"role": "system", "content": "You are a helpful assistant."},
           {"role": "user", "content": "Does Azure OpenAI support customer managed keys?"},
           {"role": "assistant", "content": "Yes, customer managed keys are supported by Azure OpenAI."},
           {"role": "user", "content": "Do other Azure AI services support this too?"}
       ]
   )

   print(response.choices[0].message.content)
    ```

>**NOTE**: It might take a few minutes before the fine-tuned model deployment is completed. You can verify it in the **Deployments** page in Azure AI Foundry.

## Clean up

When you're done with your Azure OpenAI resource, remember to delete the deployment or the entire resource in the **Azure portal** at `https://portal.azure.com`.

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
