---
lab:
    title: 'Retrieval Augmented Generation using Azure Databricks'
---

# Retrieval Augmented Generation using Azure Databricks

Retrieval Augmented Generation (RAG) is a cutting-edge approach in AI that enhances large language models by integrating external knowledge sources. Azure Databricks offers a robust platform for developing RAG applications, allowing for the transformation of unstructured data into a format suitable for retrieval and response generation. This process involves a series of steps including understanding the user's query, retrieving relevant data, and generating a response using a language model. The framework provided by Azure Databricks supports rapid iteration and deployment of RAG applications, ensuring high-quality, domain-specific responses that can include up-to-date information and proprietary knowledge.

This lab will take approximately **40** minutes to complete.

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

> **Tip**: If you already have a cluster with a 16.4 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the **msl-*xxxxxxx*** resource group that was created by the script (or the resource group containing your existing Azure Databricks workspace)
1. Select your Azure Databricks Service resource (named **databricks-*xxxxxxx*** if you used the setup script to create it).
1. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

1. In the sidebar on the left, select the **(+) New** task, and then select **Cluster**.
1. In the **New Cluster** page, create a new cluster with the following settings:
    - **Cluster name**: *User Name's* cluster (the default cluster name)
    - **Policy**: Unrestricted
    - **Machine learning**: Enabled
    - **Databricks runtime**: 16.4 LTS
    - **Use Photon Acceleration**: <u>Un</u>selected
    - **Worker type**: Standard_D4ds_v5
    - **Single node**: Checked

1. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region. You can specify a region as a parameter for the setup script like this: `./mslearn-databricks/setup.ps1 eastus`

## Install required libraries

1. In the sidebar, use the **(+) New** link to create a **Notebook**. In the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.
1. In the first code cell, enter and run the following code to install the necessary libraries:
   
    ```python
   %pip install faiss-cpu
   dbutils.library.restartPython()
    ```
   
## Ingest data

1. In a new browser tab, download the [sample file](https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/enwiki-latest-pages-articles.xml) that will be used as data in this exercise: `https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/enwiki-latest-pages-articles.xml`
1. Back in the Databricks workspace tab, with your notebook open, select the **Catalog (CTRL + Alt + C)** explorer and select the ➕ icon to **Add data**.
1. In the **Add data** page, select **Upload files to DBFS**.
1. In the **DBFS** page, name the target directory `RAG_lab` and upload the .xml file you saved earlier.
1. In the sidebar, select **Workspace** and open your notebook again.
1. In a new code cell, enter the following code to create a dataframe from the raw data:

    ```python
   from pyspark.sql import SparkSession

   # Create a Spark session
   spark = SparkSession.builder \
       .appName("RAG-DataPrep") \
       .getOrCreate()

   # Read the XML file
   raw_df = spark.read.format("xml") \
       .option("rowTag", "page") \
       .load("/FileStore/tables/RAG_lab/enwiki_latest_pages_articles.xml")

   # Show the DataFrame
   raw_df.show(5)

   # Print the schema of the DataFrame
   raw_df.printSchema()
    ```

1. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.
1. In a new cell, run the following code to clean and preprocess the data to extract the relevant text fields:

    ```python
   from pyspark.sql.functions import col

   clean_df = raw_df.select(col("title"), col("revision.text._VALUE").alias("text"))
   clean_df = clean_df.na.drop()
   clean_df.show(5)
    ```

## Generate embeddings and implement vector search

FAISS (Facebook AI Similarity Search) is an open-source vector database library developed by Meta AI, designed for efficient similarity search and clustering of dense vectors. FAISS enables fast and scalable nearest neighbor searches, and can be integrated with hybrid search systems to combine vector-based similarity with traditional keyword-based techniques, enhancing the relevance of search results.

1. In a new cell, run the following code to load the pre-trained `all-MiniLM-L6-v2` model and convert text to embeddings:

    ```python
   from sentence_transformers import SentenceTransformer
   import numpy as np
    
   # Load pre-trained model
   model = SentenceTransformer('all-MiniLM-L6-v2')
    
   # Function to convert text to embeddings
   def text_to_embedding(text):
       embeddings = model.encode([text])
       return embeddings[0]
    
   # Convert the DataFrame to a Pandas DataFrame
   pandas_df = clean_df.toPandas()
    
   # Apply the function to get embeddings
   pandas_df['embedding'] = pandas_df['text'].apply(text_to_embedding)
   embeddings = np.vstack(pandas_df['embedding'].values)
    ```

1. In a new cell, run the following code to create and query the FAISS index:

    ```python
   import faiss
    
   # Create a FAISS index
   d = embeddings.shape[1]  # dimension
   index = faiss.IndexFlatL2(d)  # L2 distance
   index.add(embeddings)  # add vectors to the index
    
   # Perform a search
   query_embedding = text_to_embedding("Anthropology fields")
   k = 1  # number of nearest neighbors
   distances, indices = index.search(np.array([query_embedding]), k)
    
   # Get the results
   results = pandas_df.iloc[indices[0]]
   display(results)
    ```

Verify that the output finds the corresponding Wiki page related to the query prompt.

## Augment prompts with retrieved data

Now we can enchance the capabilities of large language models by providing them with additional context from external data sources. By doing so, the models can generate more accurate and contextually relevant responses.

1. In a new cell, run the following code to combine the retrieved data with the user's query to create a rich prompt for the LLM.

    ```python
   from transformers import pipeline
    
   # Load the summarization model
   summarizer = pipeline("summarization", model="facebook/bart-large-cnn", framework="pt")
    
   # Extract the string values from the DataFrame column
   text_data = results["text"].tolist()
    
   # Pass the extracted text data to the summarizer function
   summary = summarizer(text_data, max_length=512, min_length=100, do_sample=True)
    
   def augment_prompt(query_text):
       context = " ".join([item['summary_text'] for item in summary])
       return f"{context}\n\nQuestion: {query_text}\nAnswer:"
    
   prompt = augment_prompt("Explain the significance of Anthropology")
   print(prompt)
    ```

1. In a new cell, run the following code to use an LLM to generate responses.

    ```python
   from transformers import GPT2LMHeadModel, GPT2Tokenizer

   tokenizer = GPT2Tokenizer.from_pretrained("gpt2")
   model = GPT2LMHeadModel.from_pretrained("gpt2")

   inputs = tokenizer(prompt, return_tensors="pt")
   outputs = model.generate(
       inputs["input_ids"], 
       max_length=300, 
       num_return_sequences=1, 
       repetition_penalty=2.0, 
       top_k=50, 
       top_p=0.95, 
       temperature=0.7,
       do_sample=True
   )
   response = tokenizer.decode(outputs[0], skip_special_tokens=True)

   print(response)
    ```

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
