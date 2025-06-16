---
lab:
    title: 'Explore Large Language Models with Azure Databricks'
---

# Explore Large Language Models with Azure Databricks

Large Language Models (LLMs) can be a powerful asset for Natural Language Processing (NLP) tasks when integrated with Azure Databricks and Hugging Face Transformers. Azure Databricks provides a seamless platform to access, fine-tune, and deploy LLMs, including pre-trained models from Hugging Face's extensive library. For model inference, Hugging Face's pipelines class simplifies the use of pre-trained models, supporting a wide range of NLP tasks directly within the Databricks environment.

This lab will take approximately **30** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

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

7. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer.

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 13.3 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace)
1. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).
1. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

1. In the sidebar on the left, select the **(+) New** task, and then **More** and then select **Cluster**.
1. In the **New Cluster** page, create a new cluster with the following settings:
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

1. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region. You can specify a region as a parameter for the setup script like this: `./mslearn-databricks/setup.ps1 eastus`

## Install required libraries

1. In your cluster's page, select the **Libraries** tab.

2. Select **Install New**.

3. Select **PyPI** as the library source and type `transformers==4.44.0` in the **Package** field.

4. Select **Install**.

## Load pre-trained models

1. In the Databricks workspace, go to the **Workspace** section.

2. Select **Create** and then select **Notebook**.

3. Name your notebook and select `Python` as the language.

4. In the first code cell, enter and run the following code:

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

A summarization pipeline generates concise summaries from longer texts. By specifying a length range (`min_length`, `max_length`) and whether it will use sampling or not (`do_sample`), we can determine how precise or creative the generated summary will be. 

1. In a new code cell, enter the following code:

     ```python
    text = "Large language models (LLMs) are advanced AI systems capable of understanding and generating human-like text by learning from vast datasets. These models, which include OpenAI's GPT series and Google's BERT, have transformed the field of natural language processing (NLP). They are designed to perform a wide range of tasks, from translation and summarization to question-answering and creative writing. The development of LLMs has been a significant milestone in AI, enabling machines to handle complex language tasks with increasing sophistication. As they evolve, LLMs continue to push the boundaries of what's possible in machine learning and artificial intelligence, offering exciting prospects for the future of technology."
    summary = summarizer(text, max_length=75, min_length=25, do_sample=False)
    print(summary)
     ```

2. Run the cell to see the summarized text.

### Analyze Sentiment

The sentiment analysis pipeline determines the sentiment of a given text. It classifies the text into categories such as positive, negative, or neutral.

1. In a new code cell, enter the following code:

     ```python
    text = "I love using Azure Databricks for NLP tasks!"
    sentiment = sentiment_analyzer(text)
    print(sentiment)
     ```

2. Run the cell to see the sentiment analysis result.

### Translate Text

The translation pipeline converts text from one language to another. In this exercise, the task used was `translation_en_to_fr`, which means it will translate any given text from English to French.

1. In a new code cell, enter the following code:

     ```python
    text = "Hello, how are you?"
    translation = translator(text)
    print(translation)
     ```

2. Run the cell to see the translated text in French.

### Classify Text

The zero-shot classification pipeline allows a model to classify text into categories it hasn’t seen during training. Therefore, it requires predefined labels as a `candidate_labels` parameter.

1. In a new code cell, enter the following code:

     ```python
    text = "Azure Databricks is a powerful platform for big data analytics."
    labels = ["technology", "health", "finance"]
    classification = classifier(text, candidate_labels=labels)
    print(classification)
     ```

2. Run the cell to see the zero-shot classification results.

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
