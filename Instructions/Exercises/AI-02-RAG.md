---
lab:
    title: 'Retrieval Augmented Generation using Azure Databricks'
---

# Retrieval Augmented Generation using Azure Databricks

Retrieval Augmented Generation (RAG) is a cutting-edge approach in AI that enhances large language models by integrating external knowledge sources. Azure Databricks offers a robust platform for developing RAG applications, allowing for the transformation of unstructured data into a format suitable for retrieval and response generation. This process involves a series of steps including understanding the user's query, retrieving relevant data, and generating a response using a language model. The framework provided by Azure Databricks supports rapid iteration and deployment of RAG applications, ensuring high-quality, domain-specific responses that can include up-to-date information and proprietary knowledge.

This lab will take approximately **30** minutes to complete.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

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

> **Tip**: If you already have a cluster with a 13.3 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

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
    - **Databricks runtime version**: *Select the **<u>ML</u>** edition of the latest non-beta version of the runtime (**Not** a Standard runtime version) that:*
        - *Does **not** use a GPU*
        - *Includes Scala > **2.11***
        - *Includes Spark > **3.4***
    - **Use Photon Acceleration**: <u>Un</u>selected
    - **Node type**: Standard_DS3_v2
    - **Terminate after** *20* **minutes of inactivity**

1. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region. You can specify a region as a parameter for the setup script like this: `./mslearn-databricks/setup.ps1 eastus`

## Install required libraries

1. In your cluster's page, select the **Libraries** tab.

2. Select **Install New**.

3. Select **PyPI** as the library source and type `transformers==4.44.0` in the **Package** field.

4. Select **Install**.

5. Repeat the steps above to install `sentence-transformers==3.0.1` as well.
   
## Create a notebook and ingest data

1. In the sidebar, use the **(+) New** link to create a **Notebook**. In the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

2. In the first cell of the notebook, enter the following code, which uses *shell* commands to download data files from GitHub into the file system used by your cluster.

     ```python
    %sh
    rm -r /dbfs/RAG_lab
    mkdir /dbfs/RAG_lab
    wget -O /dbfs/RAG_lab/enwiki-latest-pages-articles.xml https://github.com/MicrosoftLearning/mslearn-databricks/raw/main/data/enwiki-latest-pages-articles.xml
     ```

3. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.

4. In a new cell, run the following code to create a dataframe from the raw data:

     ```python
    from pyspark.sql import SparkSession

    # Create a Spark session
    spark = SparkSession.builder \
        .appName("RAG-DataPrep") \
        .getOrCreate()

    # Read the XML file
    raw_df = spark.read.format("xml") \
        .option("rowTag", "page") \
        .load("/RAG_lab/enwiki-latest-pages-articles.xml")

    # Show the DataFrame
    df.show(5)

    # Print the schema of the DataFrame
    df.printSchema()
     ```

5. In a new cell, run the following code to clean and preprocess the data to extract relevant text fields:

     ```python
    from pyspark.sql.functions import col

    clean_df = raw_df.select(col("title"), col("revision.text._VALUE").alias("text"))
    clean_df = clean_df.na.drop()
    clean_df.show(5)
     ```
     
## Generate embeddings

The Sentence Transformers library is a powerful tool for generating embeddings for text data. It allows users to easily access and utilize pre-trained models for creating embeddings that capture the semantic meaning of sentences. The users can choose the model that best fits their needs for a variety of applications such as semantic search or textual similarity tasks. 

1. In a new cell, run the following code to generate embeddings for the text.

     ```python
    from sentence_transformers import SentenceTransformer

    model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')

    def embed_text(text):
        return model.encode(text).tolist()

    # Apply the embedding function to the dataset
    from pyspark.sql.functions import udf
    from pyspark.sql.types import ArrayType, FloatType

    embed_udf = udf(embed_text, ArrayType(FloatType()))
    embedded_df = clean_df.withColumn("embeddings", embed_udf(col("text")))
    embedded_df.show(5)
     ```

2. Save the embedded data into a Delta table for efficient retrieval.

     ```python
    embedded_df.write.format("delta").mode("overwrite").save("/mnt/delta/wiki_embeddings")
     ```

3. Create a Delta table

     ```python
    CREATE TABLE IF NOT EXISTS wiki_embeddings
     LOCATION '/mnt/delta/wiki_embeddings'
     ```
     
## Implement vector search

Databricks' Mosaic AI Vector Search is a vector database solution integrated within the Azure Databricks Platform. It optimizes the storage and retrieval of embeddings utilizing the Hierarchical Navigable Small World (HNSW) algorithm. It allows for efficient nearest neighbor searches, and its hybrid keyword-similarity search capability provides more relevant results by combining vector-based and keyword-based search techniques.

1. In a new cell, run the following code to configure Azure Databricks' vector search capabilities.

     ```python
    from databricks.feature_store import FeatureStoreClient

    fs = FeatureStoreClient()

    fs.create_table(
        name="wiki_embeddings_vector_store",
        primary_keys=["title"],
        df=embedded_df,
        description="Vector embeddings for Wikipedia articles."
    )
     ```
2. In a new cell, run the following code to search for relevant documents based on a query vector.

     ```python
    def search_vectors(query_text, top_k=5):
        query_embedding = model.encode([query_text]).tolist()
        query_df = spark.createDataFrame([(query_text, query_embedding)], ["query_text", "query_embedding"])
        
        results = fs.search_table(
            name="wiki_embeddings_vector_store",
            vector_column="embeddings",
            query=query_df,
            top_k=top_k
        )
        return results

    query = "Machine learning applications"
    search_results = search_vectors(query)
    search_results.show()
     ```

## Augment Prompts with Retrieved Data:

1. Combine the retrieved data with the user's query to create a rich prompt for the LLM.

     ```python
    def augment_prompt(query_text):
        search_results = search_vectors(query_text)
        context = " ".join(search_results.select("text").rdd.flatMap(lambda x: x).collect())
        return f"Query: {query_text}\nContext: {context}"

    prompt = augment_prompt("Explain the significance of the Turing test")
    print(prompt)
     ```

- Generate Responses with LLM:
    2. Use an LLM like GPT-3 or similar models from Hugging Face to generate responses.

    ```python
    from transformers import GPT2LMHeadModel, GPT2Tokenizer

    tokenizer = GPT2Tokenizer.from_pretrained("gpt2")
    model = GPT2LMHeadModel.from_pretrained("gpt2")

    inputs = tokenizer(prompt, return_tensors="pt")
    outputs = model.generate(inputs["input_ids"], max_length=500, num_return_sequences=1)
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)

    print(response)
    ```

## Step 8: Evaluation and Optimization
- Evaluate the Quality of Generated Responses:
    1. Assess the relevance, coherence, and accuracy of the generated responses.
    2. Collect user feedback and iterate on the prompt augmentation process.

- Optimize the RAG Workflow:
    1. Experiment with different embedding models, chunk sizes, and retrieval parameters to optimize performance.
    2. Monitor the system's performance and make adjustments to improve accuracy and efficiency.

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
