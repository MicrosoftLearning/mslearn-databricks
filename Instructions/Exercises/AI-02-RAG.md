# Exercise 02 - Retrieval Augmented Generation using Azure Databricks

## Objective
This exercise guides you through setting up a Retrieval Augmented Generation (RAG) workflow on Azure Databricks. The process involves ingesting data, creating vector embeddings, storing these embeddings in a vector database, and using them to augment the input for a generative model.

## Requirements
An active Azure subscription. If you do not have one, you can sign up for a [free trial](https://azure.microsoft.com/en-us/free/).

## Estimated time: 40 minutes

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

## Step 3: Data Preparation
- Ingest Data
    1. Download a sample dataset of Wikipedia articles from [here](https://dumps.wikimedia.org/enwiki/latest/).
    2. Upload the dataset to Azure Data Lake Storage or directly to Azure Databricks File System.

- Load Data into Azure Databricks
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("RAG-DataPrep").getOrCreate()
raw_data_path = "/mnt/data/wiki_sample.json"  # Adjust the path as necessary

raw_df = spark.read.json(raw_data_path)
raw_df.show(5)
```

- Data Cleaning and Preprocessing
    1. Clean and preprocess the data to extract relevant text fields.

    ```python
    from pyspark.sql.functions import col

    clean_df = raw_df.select(col("title"), col("text"))
    clean_df = clean_df.na.drop()
    clean_df.show(5)
    ```
## Step 4: Generating Embeddings
- Install Required Libraries
    1. Ensure you have the transformers and sentence-transformers libraries installed.

    ```python
    %pip install transformers sentence-transformers
    ```
- Generate Embeddings
    1. Use a pre-trained model to generate embeddings for the text.

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

## Step 5: Storing Embeddings
- Store Embeddings in Delta Tables
    1. Save the embedded data into a Delta table for efficient retrieval.

    ```python
    embedded_df.write.format("delta").mode("overwrite").save("/mnt/delta/wiki_embeddings")
    ```

    2. Create a Delta table

    ```python
    CREATE TABLE IF NOT EXISTS wiki_embeddings
     LOCATION '/mnt/delta/wiki_embeddings'
    ```
## Step 6: Implementing Vector Search
- Configure Vector Search
    1. Use Databricks' vector search capabilities or integrate with a vector database like Milvus or Pinecone.

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
- Perform Vector Search
    1. Implement a functon to search for relevant documents based on a query vector.

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

## Step 7: Generative Augmentation
- Augment Prompts with Retrieved Data:
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

## Step 9: Clean Up Resources
- Terminate the Cluster:
    1. Go back to the "Compute" page, select your cluster, and click "Terminate" to stop the cluster.

- Optional: Delete the Databricks Service:
    1. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

By following these steps, you will have implemented a Retrieval Augmented Generation (RAG) system using Azure Databricks. This lab demonstrates how to preprocess data, generate embeddings, store them efficiently, perform vector searches, and use generative models to create enriched responses. The approach can be adapted to various domains and datasets to enhance the capabilities of AI-driven applications.