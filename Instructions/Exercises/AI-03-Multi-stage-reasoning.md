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
    - **Name**: *A unique name of your choice*
    - **Region**: *Make a **random** choice from any of the following regions*\*
        - North Central US
        - Sweden Central
    - **Default project name**: *Leave the pre-filled default or enter a custom project name*
4. Select **Review + create**, then select **Create** and wait for deployment to complete.

> \* Foundry resources are constrained by regional quotas. The listed regions include default quota for the model type(s) used in this exercise. Randomly choosing a region reduces the risk of a single region reaching its quota limit in scenarios where you are sharing a subscription with other users. In the event of a quota limit being reached later in the exercise, there's a possibility you may need to create another resource in a different region.

5. Once deployment completes, go to the deployed resource. In the left pane, under **Resource Management**, select **Keys and Endpoint**, then on the **Foundry** tab, copy the **API endpoint** — you will use it later in this exercise.

6. In the **Overview** page, select **Go to Foundry portal** to open your resource in the Foundry portal (or navigate directly to `https://ai.azure.com`).

7. In **Microsoft Foundry**, select the project within your Foundry resource. A default project is created automatically — select it to open it. If no project exists, create one:
    - Select **+ New project** in the left navigation.
    - Enter a **Project name** and select **Create project**.
    - Wait for the project to be created.

8. In a new browser tab, return to the **Azure portal** at `https://portal.azure.com` and launch Cloud Shell. Run the following command to get a temporary authorization token for API calls. Copy the `accessToken` value and save it alongside the endpoint you copied in step 5.

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
    - **Deployment type**: Global Standard
    - **Model version** *(under Model version settings)*: *2025-04-14*
    - **Model version upgrade policy** *(under Model version settings)*: Upgrade once new default version becomes available
    - **Tokens per minute rate limit**: 10K\*
    - **Guardrails**: DefaultV2

    Then select **Deploy** at the bottom of the page.

1. Return to the **Deployments** page and create a new deployment of the **text-embedding-ada-002** model with the following settings:
    - **Deployment name**: *text-embedding-ada-002*
    - **Deployment type**: Global Standard
    - **Tokens per minute rate limit**: 10K\*
    - **Guardrails**: DefaultV2

    Then select **Deploy** at the bottom of the page.

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
    - **Pricing tier**: Premium (+ Role-based access controls)
    - **Workspace type**: Hybrid
    - **Managed Resource Group name**: *Leave blank*

> **Note**: Azure Databricks does not need to be in the same region as your Foundry resource. If cluster creation fails due to quota limits in your chosen region, try deleting the workspace and creating a new one in a different region.

1. Select **Review + create**, and once validation succeeds, select **Create**.

1. When deployment is complete, select **Go to resource**, then select **Launch Workspace** to open your Azure Databricks workspace in a new browser tab.

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 17.3 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the sidebar on the left, select the **(+) New** task, select **More**, and then select **Cluster**.
1. In the **New Cluster** page, create a new cluster with the following settings:
    - **Cluster name**: *User Name's* cluster (the default cluster name)
    - **Policy**: Unrestricted
    - **Machine learning**: Enabled
    - **Databricks runtime**: 17.3 LTS
    - **Use Photon Acceleration**: <u>Un</u>selected
    - **Worker type**: Standard_D4ds_v5
    - **Single node**: Checked
    - **Terminate after**: 30 minutes of inactivity
1. Select **Create**

1. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Create a notebook and install required libraries

1. In the sidebar on the left, use the **(+) New** link to create a **Notebook**.

1. Name your notebook and select `Python` as the language. In the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

1. In the first code cell, enter and run the following code to install the necessary libraries:
   
    ```python
   %pip install langchain openai langchain_openai langchain-community faiss-cpu
    ```

    > **Note**: You may see warnings that package versions are not pinned, or that core Python package versions changed. These are advisory only and won't affect the lab — the `%restart_python` command in the next step restarts the Python environment to apply the updates.

1. After the installation is complete, restart the kernel in a new cell:

    ```python
   %restart_python
    ```

1. In a new cell, run the following code with the access information you copied earlier to assign persistent environment variables for authentication:

    ```python
   import os
   os.environ["AZURE_OPENAI_ENDPOINT"] = "your_endpoint"  # e.g. https://yourresource.services.ai.azure.com/
   os.environ["COGNITIVE_SERVICES_TOKEN"] = "your_cognitiveservices_access_token"  # from: az account get-access-token --resource https://cognitiveservices.azure.com
    ```

    > **Note**: The access token expires after approximately 60 minutes. If you encounter authentication errors during the lab, re-run the Cloud Shell command and update this cell.
    
## Create a Vector Index and Store Embeddings

In this lab, you're building a retrieval-augmented generation (RAG) pipeline using LangChain. Before the language model can answer questions, it needs a knowledge base to search. In this section, you convert sample documents into vector embeddings and store them in a FAISS index. Later, the retriever uses this index to find the most relevant documents for a given query, and passes them to the model as context.

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
       openai_api_version="2025-04-01-preview",
       chunk_size=1
   )
    ```
     
1. In a new cell, run the following code to create a vector index using the known dimension for `text-embedding-ada-002` embeddings:

    ```python
   import faiss
      
   index = faiss.IndexFlatL2(1536)  # text-embedding-ada-002 always produces 1536-dimensional vectors
    ```

## Build a Retriever-based Chain

A retriever component fetches relevant documents or data based on a query. This is particularly useful in applications that require the integration of large amounts of data for analysis, such as in retrieval-augmented generation systems.

1. In a new cell, run the following code to create a retriever that can search the vector index for the most similar texts.

    ```python
   from langchain_community.vectorstores import FAISS
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
   from langchain_core.output_parsers import StrOutputParser
   from operator import itemgetter
     
   llm = AzureChatOpenAI(
       deployment_name="gpt-4.1",
       model_name="gpt-4.1",
       azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
       api_version="2025-04-01-preview",
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

   def format_docs(docs):
       return "\n\n".join(doc.page_content for doc in docs)

   qa_chain1 = (
       {
           "context": itemgetter("input") | retriever | format_docs,
           "input": itemgetter("input")
       }
       | prompt1
       | llm
       | StrOutputParser()
   )
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
