# Exercise 01 - Common Applications with Large Language Models

## Objective
This exercise focuses on how to leverage Large Language Models (LLMs) for common Natural Language Processing (NLP) tasks using Azure Databricks.

## Requirements
An active Azure subscription. If you do not have one, you can sign up for a [free trial](https://azure.microsoft.com/en-us/free/).

## Estimated time: 30 minutes

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

## Step 3: Installing Required Libraries
- Install Transformers Library:
    1. In the Databricks workspace, go to the "Libraries" tab in your cluster.
    2. Click on "Install New".
    3. Select "PyPI" and search for transformers.
    4. Click "Install".

- Install Additional Libraries (optional but recommended):
    1. pip install datasets
    2. pip install torch
    3. pip install openai

## Step 4: Loading a Pre-trained Model
- Create a New Notebook:
    1. In the Databricks workspace, go to the "Workspace" section.
    2. Click on "Create" and select "Notebook".
    3. Name your notebook and select "Python" as the language.

- Load the Model

```python
from transformers import pipeline

# Load the summarization model
summarizer = pipeline("summarization")

# Load the sentiment analysis model
sentiment_analyzer = pipeline("sentiment-analysis")

# Load the translation model
translator = pipeline("translation_en_to_fr")

# Load a general purpose model for zero-shot classification and few-shot learning
classifier = pipeline("zero-shot-classification")
```

## Step 5: Summarization Task
- Summarize Text

```python
text = """Your long text here..."""
summary = summarizer(text, max_length=50, min_length=25, do_sample=False)
print(summary)
```

- Run the Cell
    1. Execute the cell to see the summarized text.

## Step 6: Sentiment Analysis Task
- Analyze Sentiment

```python
text = "I love using Azure Databricks for NLP tasks!"
sentiment = sentiment_analyzer(text)
print(sentiment)
```

- Run the Cell
    1. Execute the cell to see the sentiment analysis result.

## Step 7: Translation Task
- Translate Text

```python
text = "Hello, how are you?"
translation = translator(text)
print(translation)
```

- Run the Cell
    1. Execute the cell to see the translated text in French.

## Step 8: Zero-shot classification Task
- Classify Text

```python
text = "Azure Databricks is a powerful platform for big data analytics."
labels = ["technology", "health", "finance"]
classification = classifier(text, candidate_labels=labels)
print(classification)
```

- Run the Cell
    1. Execute the cell to see the zero-shot classification results.

## Step 9: Few-Shot learning Task

```python
from transformers import GPT2LMHeadModel, GPT2Tokenizer

# Load GPT-2 model and tokenizer
model_name = "gpt2"
model = GPT2LMHeadModel.from_pretrained(model_name)
tokenizer = GPT2Tokenizer.from_pretrained(model_name)

# Define the prompt
prompt = """The following is a conversation between a user and an AI assistant about Azure Databricks:
User: What is Azure Databricks?
AI: """

# Tokenize input
inputs = tokenizer.encode(prompt, return_tensors="pt")

# Generate text
outputs = model.generate(inputs, max_length=150, num_return_sequences=1)
generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
print(generated_text)
```

- Run the Cell
    1. Execute the cell to see the generated conversation based on few-shot learning.

## Step 10: Clean Up Resources
- Terminate the Cluster:
    1. Go back to the "Compute" page, select your cluster, and click "Terminate" to stop the cluster.

- Optional: Delete the Databricks Service:
    1. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

This lab guides you through the process of setting up and using Azure Databricks to perform common NLP tasks with Large Language Models. By following these steps, you can harness the power of LLMs to summarize text, analyze sentiment, translate languages, and classify text with zero-shot and few-shot learning.