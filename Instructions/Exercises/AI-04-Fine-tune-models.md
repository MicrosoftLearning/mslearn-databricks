---
lab:
    title: 'Fine-Tuning Large Language Models using Azure Databricks and Azure OpenAI'
---

# Fine-Tuning Large Language Models using Azure Databricks and Azure OpenAI

With Azure Databricks, users can now leverage the power of LLMs for specialized tasks by fine-tuning them with their own data, enhancing domain-specific performance. To fine-tune a language model using Azure Databricks, you can utilize the Mosaic AI Model Training interface which simplifies the process of full model fine-tuning. This feature allows you to fine-tune a model with your custom data, with checkpoints saved to MLflow, ensuring you retain complete control over the fine-tuned model. Additionally, the Hugging Face Transformers library enables you to scale out NLP batch applications and fine-tune models for large-language model applications.

This lab will take approximately **30** minutes to complete.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Provision an Azure OpenAI resource

If you don't already have one, provision an Azure OpenAI resource in your Azure subscription.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure OpenAI** resource with the following settings:
    - **Subscription**: *Select an Azure subscription that has been approved for access to the Azure OpenAI service*
    - **Resource group**: *Choose or create a resource group*
    - **Region**: *Make a **random** choice from any of the following regions*\*
        - Australia East
        - Canada East
        - East US
        - East US 2
        - France Central
        - Japan East
        - North Central US
        - Sweden Central
        - Switzerland North
        - UK South
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
   
1. In Azure AI Studio, in the pane on the left, select the **Deployments** page and view your existing model deployments. If you don't already have one, create a new deployment of the **gpt-35-turbo-16k** model with the following settings:
    - **Deployment name**: *gpt-35-turbo-16k*
    - **Model**: gpt-35-turbo-16k *(if the 16k model isn't available, choose gpt-35-turbo and name your deployment accordingly)*
    - **Model version**: *Use default version*
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
    - **Node type**: Standard_DS3_v2
    - **Terminate after** *20* **minutes of inactivity**

6. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Install required libraries

1. In your cluster's page, select the **Libraries** tab.

2. Select **Install New**.

3. Select **PyPI** as the library source and install the following Python packages:
   - `transformers==4.44.0`
   - `datasets==2.21.0`
   - `openai==1.42.0`

## Create a new notebook and load sample dataset

1. In the sidebar, use the **(+) New** link to create a **Notebook**.
   
1. Name your notebook and in the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

1. In the first code cell, enter and run the following code to load a IMDB sample dataset for sentiment analysis:
   
     ```python
    from datasets import load_dataset

    dataset = load_dataset("imdb")
     ```

## Preprocess the dataset

- Load the Dataset
    1. You can use any text dataset suitable for your fine-tuning task. For example, let's use the IMDB dataset for sentiment analysis.
    2. In your notebook, run the following code to load the dataset

    ```python
    from datasets import load_dataset

    dataset = load_dataset("imdb")
    ```

- Preprocess the Dataset
    1. Tokenize the text data using the tokenizer from the transformers library.
    2. In your notebook, add the following code:

    ```python
    from transformers import GPT2Tokenizer

    tokenizer = GPT2Tokenizer.from_pretrained("gpt2")

    def tokenize_function(examples):
        return tokenizer(examples["text"], padding="max_length", truncation=True)

    tokenized_datasets = dataset.map(tokenize_function, batched=True)
    ```

- Prepare data for fine-tuning
    1. Split the data into training and validation sets.
    2. In your notebook, add:

    ```python
    small_train_dataset = tokenized_datasets["train"].shuffle(seed=42).select(range(1000))
    small_eval_dataset = tokenized_datasets["test"].shuffle(seed=42).select(range(500))
    ```

## Step 5 - Fine-Tuning the GPT-4 Model

- Set Up the OpenAI API
    1. You'll need your Azure OpenAI API key and endpoint.
    2. In your notebook, set up the API credentials:

    ```python
    import openai

    openai.api_type = "azure"
    openai.api_key = "YOUR_AZURE_OPENAI_API_KEY"
    openai.api_base = "YOUR_AZURE_OPENAI_ENDPOINT"
    openai.api_version = "2023-05-15"
    ```
- Fine-Tune the Model
    1. GPT-4 fine-tuning is performed by adjusting hyperparameters and continuing the training process on your specific dataset.
    2. Fine-tuning can be more complex and might require batching data, customizing training loops, etc.
    3. Use the following as a basic template:

    ```python
    from transformers import GPT2LMHeadModel, Trainer, TrainingArguments

    model = GPT2LMHeadModel.from_pretrained("gpt2")

    training_args = TrainingArguments(
        output_dir="./results",
        evaluation_strategy="epoch",
        learning_rate=2e-5,
        per_device_train_batch_size=2,
        per_device_eval_batch_size=2,
        num_train_epochs=3,
        weight_decay=0.01,
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=small_train_dataset,
        eval_dataset=small_eval_dataset,
    )

    trainer.train()
    ```
    4. This code provides a basic framework for training. The parameters and datasets would need to be adapted for specific cases.

- Monitor the Training Process
    1. Databricks allows monitoring the training process through the notebook interface and integrated tools like MLflow for tracking.

## Step 6: Evaluating the Fine-Tuned Model

- Generate Predictions
    1. After fine-tuning, generate predictions on the evaluation dataset.
    2. In your notebook, add:

    ```python
    predictions = trainer.predict(small_eval_dataset)
    print(predictions)
    ```

- Evaluate the Model Performance
    1. Use metrics such as accuracy, precision, recall, and F1-score to evaluate the model.
    2. Example:

    ```python
    from sklearn.metrics import accuracy_score

    preds = predictions.predictions.argmax(-1)
    labels = predictions.label_ids
    accuracy = accuracy_score(labels, preds)
    print(f"Accuracy: {accuracy}")
    ```

- Save the Fine-Tuned Model
    1. Save the fine-tuned model to your Azure Databricks environment or Azure storage for future use.
    2. Example:

    ```python
    model.save_pretrained("/dbfs/mnt/fine-tuned-gpt4/")
    ```

## Step 7: Deploying the Fine-Tuned Model
- Package the Model for Deployment
    1. Convert the model to a format compatible with Azure OpenAI or another deployment service.

- Deploy the Model
    1. Use Azure OpenAI for deployment by registering the model via Azure Machine Learning or directly with the OpenAI endpoint.

- Test the Deployed Model
    1. Run tests to ensure that the deployed model behaves as expected and integrates smoothly with applications.

## Step 8: Clean Up Resources
- Terminate the Cluster:
    1. Go back to the "Compute" page, select your cluster, and click "Terminate" to stop the cluster.

- Optional: Delete the Databricks Service:
    1. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

This exercise provided a comprehensive guide on fine-tuning large language models like GPT-4 using Azure Databricks and Azure OpenAI. By following these steps, you will be able to fine-tune models for specific tasks, evaluate their performance, and deploy them for real-world applications.

