---
lab:
    title: 'Multi-stage Reasoning with LangChain using Azure Databricks and Azure OpenAI'
---

# Multi-stage Reasoning with LangChain using Azure Databricks and Azure OpenAI

Multi-stage reasoning is a cutting-edge approach in AI that involves breaking down complex problems into smaller, more manageable stages. LangChain, a software framework, facilitates the creation of applications that leverage large language models (LLMs). When integrated with Azure Databricks, LangChain allows for seamless data loading, model wrapping, and the development of sophisticated AI agents. This combination is particularly powerful for handling intricate tasks that require a deep understanding of context and the ability to reason across multiple steps.

This lab will take approximately **30** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Provision an Azure OpenAI resource

If you don't already have one, provision an Azure OpenAI resource in your Azure subscription.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
1. Create an **Azure OpenAI** resource with the following settings:
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

1. Wait for deployment to complete. Then go to the deployed Azure OpenAI resource in the Azure portal.

1. In the left pane, under **Resource Management**, select **Keys and Endpoint**.

1. Copy the endpoint and one of the available keys as you will use it later in this exercise.

## Deploy the required models

Azure provides a web-based portal named **Azure AI Foundry**, that you can use to deploy, manage, and explore models. You'll start your exploration of Azure OpenAI by using Azure AI Foundry to deploy a model.

> **Note**: As you use Azure AI Foundry, message boxes suggesting tasks for you to perform may be displayed. You can close these and follow the steps in this exercise.

1. In the Azure portal, on the **Overview** page for your Azure OpenAI resource, scroll down to the **Get Started** section and select the button to go to **Azure AI Foundry**.
   
1. In Azure AI Foundry, in the pane on the left, select the **Deployments** page and view your existing model deployments. If you don't already have one, create a new deployment of the **gpt-4o** model with the following settings:
    - **Deployment name**: *gpt-4o*
    - **Deployment type**: Standard
    - **Model version**: *Use default version*
    - **Tokens per minute rate limit**: 10K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled
    
1. Go back to the **Deployments** page and create a new deployment of the **text-embedding-ada-002** model with the following settings:
    - **Deployment name**: *text-embedding-ada-002*
    - **Deployment type**: Standard
    - **Model version**: *Use default version*
    - **Tokens per minute rate limit**: 10K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled

> \* A rate limit of 10,000 tokens per minute is more than adequate to complete this exercise while leaving capacity for other people using the same subscription.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
1. Create an **Azure Databricks** resource with the following settings:
    - **Subscription**: *Select the same Azure subscription that you used to create your Azure OpenAI resource*
    - **Resource group**: *The same resource group where you created your Azure OpenAI resource*
    - **Region**: *The same region where you created your Azure OpenAI resource*
    - **Name**: *A unique name of your choice*
    - **Pricing tier**: *Premium* or *Trial*

1. Select **Review + create** and wait for deployment to complete. Then go to the resource and launch the workspace.

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 16.4 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the resource group where the Azure Databricks workspace was created.
1. Select your Azure Databricks Service resource.
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

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Install required libraries

1. In the Databricks workspace, go to the **Workspace** section.
1. Select **Create** and then select **Notebook**.
1. Name your notebook and select `Python` as the language.
1. In the first code cell, enter and run the following code to install the necessary libraries:
   
    ```python
   %pip install langchain openai langchain_openai langchain-community faiss-cpu
    ```

1. After the installation is complete, restart the kernel in a new cell:

    ```python
   %restart_python
    ```

1. In a new cell, define the authentication parameters that will be used to initialize the OpenAI models, replacing `your_openai_endpoint` and `your_openai_api_key` with the endpoint and key copied earlier from your OpenAI resource:

    ```python
   endpoint = "your_openai_endpoint"
   key = "your_openai_api_key"
    ```
    
## Create a Vector Index and Store Embeddings

A vector index is a specialized data structure that allows for efficient storage and retrieval of high-dimensional vector data, which is crucial for performing fast similarity searches and nearest neighbor queries. Embeddings, on the other hand, are numerical representations of objects that capture their meaning in a vector form, enabling machines to process and understand various types of data, including text and images.

1. In a new cell, run the following code to load a sample dataset:

    ```python
   from langchain_core.documents import Document

   documents = [
        Document(page_content="Azure Databricks is a fast, easy, and collaborative Apache Spark-based analytics platform.", metadata={"date_created": "2024-08-22"}),
        Document(page_content="LangChain is a framework designed to simplify the creation of applications using large language models.", metadata={"date_created": "2024-08-22"}),
        Document(page_content="GPT-4 is a powerful language model developed by OpenAI.", metadata={"date_created": "2024-08-22"})
   ]
   ids = ["1", "2", "3"]
    ```
     
1. In a new cell, run the following code to generate embeddings using the `text-embedding-ada-002` model:

    ```python
   from langchain_openai import AzureOpenAIEmbeddings
     
   embedding_function = AzureOpenAIEmbeddings(
       deployment="text-embedding-ada-002",
       model="text-embedding-ada-002",
       azure_endpoint=endpoint,
       openai_api_key=key,
       chunk_size=1
   )
    ```
     
1. In a new cell, run the following code to create a vector index using the first text sample as a reference for the vector dimension:

    ```python
   import faiss
      
   index = faiss.IndexFlatL2(len(embedding_function.embed_query("Azure Databricks is a fast, easy, and collaborative Apache Spark-based analytics platform.")))
    ```

## Build a Retriever-based Chain

A retriever component fetches relevant documents or data based on a query. This is particularly useful in applications that require the integration of large amounts of data for analysis, such as in retrieval-augmented generation systems.

1. In a new cell, run the following code to create a retriever that can search the vector index for the most similar texts.

    ```python
   from langchain.vectorstores import FAISS
   from langchain_core.vectorstores import VectorStoreRetriever
   from langchain_community.docstore.in_memory import InMemoryDocstore

   vector_store = FAISS(
       embedding_function=embedding_function,
       index=index,
       docstore=InMemoryDocstore(),
       index_to_docstore_id={}
   )
   vector_store.add_documents(documents=documents, ids=ids)
   retriever = VectorStoreRetriever(vectorstore=vector_store)
    ```

1. In a new cell, run the following code to create a QA system using the retriever and the `gpt-4o` model:
    
    ```python
   from langchain_openai import AzureChatOpenAI
   from langchain_core.prompts import ChatPromptTemplate
   from langchain.chains.combine_documents import create_stuff_documents_chain
   from langchain.chains import create_retrieval_chain
     
   llm = AzureChatOpenAI(
       deployment_name="gpt-4o",
       model_name="gpt-4o",
       azure_endpoint=endpoint,
       api_version="2023-03-15-preview",
       openai_api_key=key,
   )

   system_prompt = (
       "Use the given context to answer the question. "
       "If you don't know the answer, say you don't know. "
       "Use three sentences maximum and keep the answer concise. "
       "Context: {context}"
   )

   prompt1 = ChatPromptTemplate.from_messages([
       ("system", system_prompt),
       ("human", "{input}")
   ])

   chain = create_stuff_documents_chain(llm, prompt1)

   qa_chain1 = create_retrieval_chain(retriever, chain)
    ```

1. In a new cell, run the following code to test the QA system:

    ```python
   result = qa_chain1.invoke({"input": "What is Azure Databricks?"})
   print(result)
    ```

    The result output should show you an answer based on the relevant document present in the sample dataset plus the generative text produced by the LLM.

## Combine chains into a multi-chain system

Langchain is a versatile tool that allows the combination of multiple chains into a multi-chain system, enhancing the capabilities of language models. This process involves stringing together various components that can process inputs in parallel or in sequence, ultimately synthesizing a final response.

1. In a new cell, run the following code to create a second chain

    ```python
   from langchain_core.prompts import ChatPromptTemplate
   from langchain_core.output_parsers import StrOutputParser

   prompt2 = ChatPromptTemplate.from_template("Create a social media post based on this summary: {summary}")

   qa_chain2 = ({"summary": qa_chain1} | prompt2 | llm | StrOutputParser())
    ```

1. In a new cell, run the following code to invoke a multi-stage chain with a given input:

    ```python
   result = qa_chain2.invoke({"input": "How can we use LangChain?"})
   print(result)
    ```

    The first chain provides an answer to the input based on the provided sample dataset, while the second chain creates a social media post based on the first chain's output. This approach allows you to handle more complex text processing tasks by chaining multiple steps together.

## Clean up

When you're done with your Azure OpenAI resource, remember to delete the deployment or the entire resource in the **Azure portal** at `https://portal.azure.com`.

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
