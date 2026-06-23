---
lab:
  title: Multi-stage Reasoning with LangChain using Azure Databricks and Microsoft Foundry
  description: You'll gain hands-on experience building sophisticated AI applications with LangChain by creating vector indexes with embeddings, implementing retriever-based chains for question-answering systems, and combining multiple chains into a multi-stage reasoning system. You'll learn how to chain LangChain components together to handle complex text processing tasks, such as retrieving relevant context from documents and then transforming that output into different formats like social media posts.
  duration: 30 minutes
  level: 400
  islab: true
  primarytopics:
    - Azure Databricks
    - Azure Portal
    - Microsoft Foundry
---

# Multi-stage Reasoning with LangChain using Azure Databricks and Microsoft Foundry

Multi-stage reasoning is a cutting-edge approach in AI that involves breaking down complex problems into smaller, more manageable stages. LangChain, a software framework, facilitates the creation of applications that leverage large language models (LLMs). When integrated with Azure Databricks, LangChain allows for seamless data loading, model wrapping, and the development of sophisticated AI agents. This combination is particularly powerful for handling intricate tasks that require a deep understanding of context and the ability to reason across multiple steps.

This lab will take approximately **30** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Create a Microsoft Foundry resource and project

If you don't already have one, create a Microsoft Foundry resource and project in your Azure subscription.

> **Note**: Creating a Foundry resource only requires a subscription, resource group, region, and name. No Key Vault or Application Insights resources are needed.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Use the following link to open the Foundry resource creation page: `https://portal.azure.com/#create/Microsoft.CognitiveServicesAIFoundry`
3. On the **Create** page, provide the following information on the **Basics** tab:
    - **Subscription**: *Select your Azure subscription*
    - **Resource group**: *Choose or create a resource group*
    - **Region**: *Make a **random** choice from any of the following regions*\*
        - North Central US
        - Sweden Central
    - **Name**: *A unique name of your choice*
4. Select **Review + create**, then select **Create** and wait for deployment to complete.

> \* Foundry resources are constrained by regional quotas. The listed regions include default quota for the model type(s) used in this exercise. Randomly choosing a region reduces the risk of a single region reaching its quota limit in scenarios where you are sharing a subscription with other users. In the event of a quota limit being reached later in the exercise, there's a possibility you may need to create another resource in a different region.

5. Once deployment completes, go to the deployed resource. In the left pane, under **Resource Management**, select **Keys and Endpoint**, then copy the **Endpoint** — you will use it later in this exercise.

6. In the **Overview** page, select **Go to Microsoft Foundry** to open your resource in the Foundry portal (or navigate directly to `https://ai.azure.com`).

7. In **Microsoft Foundry**, create a new **project** within your Foundry resource:
    - Select the project name in the upper-left corner, then select **Create new project**.
    - Enter a **Project name** and select **Create project**.
    - Wait for the project to be created.

8. Launch Cloud Shell and run the following command to get a temporary authorization token for API calls. Keep it together with the endpoint copied previously.

    ```bash
    az account get-access-token --resource https://cognitiveservices.azure.com
    ```

    >**Note**: You only need to copy the `accessToken` field value and **not** the entire JSON output.

## Deploy the required models

Microsoft Foundry allows you to deploy, manage, and explore models.

> **Note**: As you use Microsoft Foundry, message boxes suggesting tasks for you to perform may be displayed. You can close these and follow the steps in this exercise.

1. In **Microsoft Foundry**, on the home page select **View deployments** (or select **Build** in the top navigation bar, then select **Deployments**).

1. Select **Deploy** > **Deploy a base model**, search for and select **gpt-4.1**, then select **Deploy** > **Custom settings** to configure the deployment with the following settings:
    - **Deployment name**: *gpt-4.1*
    - **Deployment type**: Standard
    - **Model version**: *2025-04-14*
    - **Model version upgrade policy**: Upgrade once new default version becomes available
    - **Enable dynamic quota**: Disabled
    - **Tokens per minute rate limit**: 10K\*
    - **Guardrails**: DefaultV2

1. Return to the **Deployments** page and create a new deployment of the **text-embedding-ada-002** model with the following settings:
    - **Deployment name**: *text-embedding-ada-002*
    - **Deployment type**: Standard
    - **Model version**: *Use default version*
    - **Tokens per minute rate limit**: 10K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled

> \* A rate limit of 10,000 tokens per minute is more than adequate to complete this exercise while leaving capacity for other people using the same subscription.

2. Wait for the deployments to complete.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
1. Create an **Azure Databricks** resource with the following settings:
    - **Subscription**: *Select the same Azure subscription that you used to create your Foundry resource*
    - **Resource group**: *The same resource group where you created your Foundry resource*
    - **Workspace name**: *A unique name of your choice*
    - **Region**: *Select any available region*
    - **Pricing tier**: Premium
    - **Workspace type**: Serverless

1. Select **Review + create** and wait for deployment to complete. Then go to the resource and launch the workspace.

## Create a notebook and install required libraries

1. In the Azure portal, browse to the resource group where the Azure Databricks workspace was created.

1. Select your Azure Databricks Service resource.

1. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

    > **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

1. In the Databricks workspace, go to the **Workspace** section.

1. Select **Create** and then select **Notebook**.

1. Name your notebook and select `Python` as the language. Select **Serverless** as the default compute.

1. In the first code cell, enter and run the following code to install the necessary libraries:
   
    ```python
   %pip install langchain openai langchain_openai langchain-community faiss-cpu
    ```

1. After the installation is complete, restart the kernel in a new cell:

    ```python
   %restart_python
    ```

1. In a new cell, run the following code with the access information you copied earlier to assign persistent environment variables for authentication:

    ```python
   import os

   os.environ["AZURE_OPENAI_ENDPOINT"] = "your_foundry_endpoint"
   os.environ["COGNITIVE_SERVICES_TOKEN"] = "your_cognitiveservices_access_token"  # from: az account get-access-token --resource https://cognitiveservices.azure.com
    ```

    > **Note**: The access token expires after approximately 60 minutes. If you encounter authentication errors during the lab, re-run the Cloud Shell command and update this cell.
    
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
       azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
       azure_ad_token=os.getenv("COGNITIVE_SERVICES_TOKEN"),
       openai_api_version="2024-08-01-preview",
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
   from langchain.community_vectorstores import FAISS
   from langchain_core.vectorstores import VectorStoreRetriever

   vector_store = FAISS.from_documents(
       documents=documents,
       embedding=embedding_function,
       ids=ids,
   )
   retriever = VectorStoreRetriever(vectorstore=vector_store)
    ```

1. In a new cell, run the following code to create a QA system using the retriever and the `gpt-4.1` model:
    
    ```python
   from langchain_openai import AzureChatOpenAI
   from langchain_core.prompts import ChatPromptTemplate
   from langchain_classic.chains.combine_documents.stuff import create_stuff_documents_chain
   from langchain_classic.chains import create_retrieval_chain
     
   llm = AzureChatOpenAI(
       deployment_name="gpt-4.1",
       model_name="gpt-4.1",
       azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
       api_version="2024-08-01-preview",
       azure_ad_token=os.getenv("COGNITIVE_SERVICES_TOKEN"),
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

When you're done with your Microsoft Foundry resource, remember to delete the deployment or the entire resource in the **Azure portal** at `https://portal.azure.com`.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.
