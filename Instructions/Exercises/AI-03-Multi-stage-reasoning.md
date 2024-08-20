# Exercise 03 - Multi-stage Reasoning with LangChain using Azure Databricks and GPT-4

## Objective
This exercise aims to guide you through building a multi-stage reasoning system using LangChain on Azure Databricks. You will learn how to create a vector index, store embeddings, build a retriever-based chain, construct an image generation chain, and finally, combine these into a multi-chain system using the GPT-4 OpenAI model.

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

## Step 3: Install Required Libraries

- Open a new notebook in your workspace.
- Install the necessary libraries using the following commands:

```python
%pip install langchain openai faiss-cpu
```

- Configure OpenAI API

```python
import os
os.environ["OPENAI_API_KEY"] = "your-openai-api-key"
```

## Step 4: Create a Vector Index and Store Embeddings

- Load the Dataset
    1. Load a sample dataset for which you want to generate embeddings. For this lab, we'll use a small text dataset.

    ```python
    sample_texts = [
        "Azure Databricks is a fast, easy, and collaborative Apache Spark-based analytics platform.",
        "LangChain is a framework designed to simplify the creation of applications using large language models.",
        "GPT-4 is a powerful language model developed by OpenAI."
    ]
    ```
- Generate Embeddings
    1. Use the OpenAI GPT-4 model to generate embeddings for these texts.

    ```python
    from langchain.embeddings.openai import OpenAIEmbeddings

    embeddings_model = OpenAIEmbeddings()
    embeddings = embeddings_model.embed_documents(sample_texts)
    ``` 

- Store the Embeddings using FAISS
    1. Use FAISS to create a vector index for efficient retrieval.

    ```python
    import faiss
    import numpy as np

    dimension = len(embeddings[0])
    index = faiss.IndexFlatL2(dimension)
    index.add(np.array(embeddings))
    ```

## Step 5: Build a Retriever-based Chain
- Define a Retriever
    1. Create a retriever that can search the vector index for the most similar texts.

    ```python
    from langchain.chains import RetrievalQA
    from langchain.vectorstores.faiss import FAISS

    vector_store = FAISS(index, embeddings_model)
    retriever = vector_store.as_retriever()  
    ```

- Build the RetrievalQA Chain
    1. Create a QA system using the retriever and the GPT-4 model.
    
    ```python
    from langchain.llms import OpenAI
    from langchain.chains.question_answering import load_qa_chain

    llm = OpenAI(model_name="gpt-4")
    qa_chain = load_qa_chain(llm, retriever)
    ```

- Test the QA System
    1. Ask a question related to the texts you embedded

    ```python
    result = qa_chain.run("What is Azure Databricks?")
    print(result)
    ```

## Step 6: Build an Image Generation Chain

- Set up the Image Generation Model
    1. Configure the image generation capabilities using GPT-4.

    ```python
    from langchain.chains import SimpleChain

    def generate_image(prompt):
        # Assuming you have an endpoint or a tool to generate images from text.
        return f"Generated image for prompt: {prompt}"

    image_generation_chain = SimpleChain(input_variables=["prompt"], output_variables=["image"], transform=generate_image)
    ```

- Test the Image Generation Chain
    1. Generate an image based on a text prompt.

    ```python
    prompt = "A futuristic city with flying cars"
    image_result = image_generation_chain.run(prompt=prompt)
    print(image_result)
    ```

## Step 7: Combine Chains into a Multi-chain System
- Combine Chains
    1. Integrate the retriever-based QA chain and the image generation chain into a multi-chain system.

    ```python
    from langchain.chains import MultiChain

    multi_chain = MultiChain(
        chains=[
            {"name": "qa", "chain": qa_chain},
            {"name": "image_generation", "chain": image_generation_chain}
        ]
    )
    ```

- Run the Multi-chain System
    1. Pass a task that involves both text retrieval and image generation.

    ```python
    multi_task_input = {
        "qa": {"question": "Tell me about LangChain."},
        "image_generation": {"prompt": "A conceptual diagram of LangChain in use"}
    }

    multi_task_output = multi_chain.run(multi_task_input)
    print(multi_task_output)
    ```

## Step 8: Clean Up Resources
- Terminate the Cluster:
    1. Go back to the "Compute" page, select your cluster, and click "Terminate" to stop the cluster.

- Optional: Delete the Databricks Service:
    1. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

This concludes the exercise on multi-stage reasoning with LangChain using Azure Databricks.