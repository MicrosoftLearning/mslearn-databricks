---
lab:
    title: 'Explore Large Language Models with Azure Databricks'
---

# Explore Large Language Models with Azure Databricks

Large Language Models (LLMs) can be a powerful asset for Natural Language Processing (NLP) tasks when integrated with Azure Databricks and Hugging Face Transformers. Azure Databricks provides a seamless platform to access, fine-tune, and deploy LLMs, including pre-trained models from Hugging Face's extensive library. For model inference, Hugging Face's pipelines class simplifies the use of pre-trained models, supporting a wide range of NLP tasks directly within the Databricks environment.

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

## Install required libraries

1. In the Databricks workspace, go to the "Libraries" tab in your cluster.

2. Click on "Install New".

3. Select "PyPI" and search for transformers.

4. Click "Install".

- Install Additional Libraries (optional but recommended):
    1. pip install datasets
    2. pip install torch
    3. pip install openai

## Load a pre-trained model

1. In the Databricks workspace, go to the "Workspace" section.

2. Click on "Create" and select "Notebook".

3. Name your notebook and select "Python" as the language.

4. In the first code cell, enter the following code:

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
This will load all the necessary models for the NLP tasks presented in this exercise.

### Summarize Text

```python
text = """Your long text here..."""
summary = summarizer(text, max_length=50, min_length=25, do_sample=False)
print(summary)
```

- Run the Cell
    1. Execute the cell to see the summarized text.

### Analyze Sentiment

```python
text = "I love using Azure Databricks for NLP tasks!"
sentiment = sentiment_analyzer(text)
print(sentiment)
```

- Run the Cell
    1. Execute the cell to see the sentiment analysis result.

### Translate Text

```python
text = "Hello, how are you?"
translation = translator(text)
print(translation)
```

- Run the Cell
    1. Execute the cell to see the translated text in French.

### Classify Text

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
