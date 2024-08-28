---
lab:
    title: 'Evaluate Large Language Models using Azure Databricks and Azure OpenAI'
---

# Evaluate Large Language Models using Azure Databricks and Azure OpenAI

Evaluating large language models (LLMs) involves a series of steps to ensure the model's performance meets the required standards. MLflow LLM Evaluate, a feature within Azure Databricks, provides a structured approach to this process, including setting up the environment, defining evaluation metrics, and analyzing results. This evaluation is crucial as LLMs often do not have a single ground truth for comparison, making traditional evaluation methods inadequate.

This lab will take approximately **40** minutes to complete.

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
    - **Deployment name**: *gpt-35-turbo-16k*
    - **Model**: gpt-35-turbo-16k
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
    - **Node type**: Standard_DS3_v2
    - **Terminate after** *20* **minutes of inactivity**

6. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Install required libraries

1. In your cluster's page, select the **Libraries** tab.

2. Select **Install New**.

3. Select **PyPI** as the library source and install the following Python packages:
   - `numpy==2.1.0`
   - `requests==2.32.3`
   - `openai==1.42.0`
   - `tiktoken==0.7.0`

## Step 3: Install required Libraries

- Log in to your Azure Databricks workspace.
- Create a new notebook and select the default cluster.
- Run the following commands to install the necessary Python libraries:

```python
%pip install openai
%pip install transformers
%pip install datasets
```

- Configure OpenAI API Key:
    1. Add your Azure OpenAI API key to the notebook:

    ```python
    import openai
    openai.api_key = "your-openai-api-key"
    ```

## Step 4: Define Evaluation Metrics
- Define Common Evaluation Metrics:
    1. In this step, you will define evaluation metrics such as Perplexity, BLEU score, ROUGE score, and accuracy depending on the task.

    ```python
    from datasets import load_metric

    # Example: Load BLEU metric
    bleu_metric = load_metric("bleu")
    rouge_metric = load_metric("rouge")

    def compute_bleu(predictions, references):
        return bleu_metric.compute(predictions=predictions, references=references)

    def compute_rouge(predictions, references):
        return rouge_metric.compute(predictions=predictions, references=references)
    ```

- Define Task-specific Metrics:
    1. Depending on the use case, define other relevant metrics. For example, for sentiment analysis, define accuracy:

    ```python
    from sklearn.metrics import accuracy_score

    def compute_accuracy(predictions, references):
        return accuracy_score(references, predictions)
    ```

## Step 5: Prepare the Dataset
- Load a Dataset
    1. Use the datasets library to load a pre-defined dataset. For this lab, you can use a simple dataset like the IMDB movie reviews dataset for sentiment analysis:

    ```python
    from datasets import load_dataset

    dataset = load_dataset("imdb")
    test_data = dataset["test"]
    ```

- Preprocess the Data
    1. Tokenize and preprocess the dataset to be compatible with the GPT-4 model:

    ```python
    from transformers import GPT2Tokenizer

    tokenizer = GPT2Tokenizer.from_pretrained("gpt2")

    def preprocess_function(examples):
        return tokenizer(examples["text"], truncation=True, padding=True)

    tokenized_data = test_data.map(preprocess_function, batched=True)
    ```

## Step 6: Evaluate the GPT-4 Model
- Generate Predictions:
    1. Use the GPT-4 model to generate predictions on the test dataset

    ```python
    def generate_predictions(input_texts):
    predictions = []
    for text in input_texts:
        response = openai.Completion.create(
            model="gpt-4",
            prompt=text,
            max_tokens=50
        )
        predictions.append(response.choices[0].text.strip())
    return predictions

    input_texts = tokenized_data["text"]
    predictions = generate_predictions(input_texts)
    ```

- Compute Evaluation Metrics
    1. Compute the evaluation metrics based on the predictions generated by the GPT-4 model

    ```python
    # Example: Compute BLEU and ROUGE scores
    bleu_score = compute_bleu(predictions, tokenized_data["text"])
    rouge_score = compute_rouge(predictions, tokenized_data["text"])

    print("BLEU Score:", bleu_score)
    print("ROUGE Score:", rouge_score)
    ```

    2. If you are evaluating for a specific task like sentiment analysis, compute the accuracy

    ```python
    # Assuming binary sentiment labels (positive/negative)
    actual_labels = test_data["label"]
    predicted_labels = [1 if "positive" in pred else 0 for pred in predictions]

    accuracy = compute_accuracy(predicted_labels, actual_labels)
    print("Accuracy:", accuracy)
    ```

## Step 7: Analyze and Interpret Results

- Interpret the Results
    1. Analyze the BLEU, ROUGE, or accuracy scores to determine how well the GPT-4 model is performing on your task.
    2. Discuss potential reasons for any discrepancies and consider ways to improve the model’s performance (e.g., fine-tuning, more data preprocessing).

- Visualize the Results
    1. Optionally, you can visualize the results using Matplotlib or any other visualization tool.

    ```python
    import matplotlib.pyplot as plt

    # Example: Plot accuracy scores
    plt.bar(["Accuracy"], [accuracy])
    plt.ylabel("Score")
    plt.title("Model Evaluation Metrics")
    plt.show()
    ```

## Step 8: Experiment with Different Scenarios

- Experiment with Different Prompts
    1. Modify the prompt structure to see how it affects the model’s performance.

- Evaluate on Different Datasets
    1. Try using a different dataset to evaluate the GPT-4 model's versatility across various tasks.

- Optimize Evaluation Metrics
    1. Experiment with hyperparameters like temperature, max tokens, etc., to optimize the evaluation metrics.

## Step 9: Clean Up Resources
- Terminate the Cluster:
    1. Go back to the "Compute" page, select your cluster, and click "Terminate" to stop the cluster.

- Optional: Delete the Databricks Service:
    1. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

This exercise guides you through the process of evaluating a large language model using Azure Databricks and the GPT-4 OpenAI model. By completing this exercise, you will gain insights into the model's performance and understand how to improve and fine-tune the model for specific tasks.
