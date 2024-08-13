# Exercise 04 - Fine-Tuning Large Language Models using Azure Databricks and Azure OpenAI

## Objective
This exercise will guide you through the process of fine-tuning a large language model (LLM) using Azure Databricks and Azure OpenAI. You will learn how to set up the environment, preprocess data, and fine-tune an LLM on custom data to achieve specific NLP tasks.

## Requirements
An active Azure subscription. If you do not have one, you can sign up for a [free trial](https://azure.microsoft.com/en-us/free/).

## Step 1: Provision Azure Databricks
- Login to Azure Portal:
    1. Go to Azure Portal and sign in with your credentials.
- Create Databricks Service:
    1. Navigate to "Create a resource" > "Analytics" > "Azure Databricks".
    2. Enter the necessary details like workspace name, subscription, resource group (create new or select existing), and location.
    3. Select the pricing tier (choose standard for this lab).
    4. Click "Review + create" and then "Create" once validation passes.

## Step 2: Launch Workspace and Create a Cluster
- Launch Databricks Workspace:
    1. Once the deployment is complete, go to the resource and click "Launch Workspace".
- Create a Spark Cluster:
    1. In the Databricks workspace, click "Compute" on the sidebar, then "Create compute".
    2. Specify the cluster name and select a runtime version of Spark.
    3. Choose the Worker type as "Standard" and node type based on available options (choose smaller nodes for cost-efficiency).
    4. Click "Create compute".

## Step 3: Install required libraries
- In the "Libraries" tab of your cluster, click on "Install New."
- Install the following Python packages:
    1. transformers
    2. datasets
    3. azure-ai-openai
- Optionally, you can also install any other necessary packages like torch.

### Create new Notebook
- Go to the "Workspace" section and click on "Create" > "Notebook."
- Name your notebook (e.g., Fine-Tuning-GPT4) and choose Python as the default language.
- Attach the notebook to your cluster.

## Step 4 - Preparing the Dataset

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

