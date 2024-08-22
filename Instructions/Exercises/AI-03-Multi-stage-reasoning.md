---
lab:
    title: 'Multi-stage Reasoning with LangChain using Azure Databricks and Azure OpenAI'
---

# Multi-stage Reasoning with LangChain using Azure Databricks and Azure OpenAI

Multi-stage reasoning is a cutting-edge approach in AI that involves breaking down complex problems into smaller, more manageable stages. LangChain, a software framework, facilitates the creation of applications that leverage large language models (LLMs). When integrated with Azure Databricks, LangChain allows for seamless data loading, model wrapping, and the development of sophisticated AI agents. This combination is particularly powerful for handling intricate tasks that require a deep understanding of context and the ability to reason across multiple steps.

This lab will take approximately **40** minutes to complete.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Provision an Azure OpenAI resource

If you don't already have one, provision an Azure OpenAI resource in your Azure subscription.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure OpenAI** resource with the following settings:
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

3. Wait for deployment to complete. Then go to the deployed Azure OpenAI resource in the Azure portal.

4. In the left pane, under **Resource Management**, select **Keys and Endpoint**.

5. Copy the endpoint and one of the available keys as you will use it later in this exercise.

## Deploy a model

Azure provides a web-based portal named **Azure AI Studio**, that you can use to deploy, manage, and explore models. You'll start your exploration of Azure OpenAI by using Azure AI Studio to deploy a model.

> **Note**: As you use Azure AI Studio, message boxes suggesting tasks for you to perform may be displayed. You can close these and follow the steps in this exercise.

1. In the Azure portal, on the **Overview** page for your Azure OpenAI resource, scroll down to the **Get Started** section and select the button to go to **Azure AI Studio**.
1. In Azure AI Studio, in the pane on the left, select the **Deployments** page and view your existing model deployments. If you don't already have one, create a new deployment of the **gpt-35-turbo-16k** model with the following settings:
    - **Deployment name**: *gpt-35-turbo-16k*
    - **Model**: gpt-35-turbo-16k *(if the 16k model isn't available, choose gpt-35-turbo and name your deployment accordingly)*
    - **Model version**: *Use default version*
    - **Deployment type**: Standard
    - **Tokens per minute rate limit**: 5K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled
    
1. Go back to the **Deployments** page and create a new deployment of the **text-embedding-ada-002** model with the following settings:
    - **Deployment name**: *text-embedding-ada-002*
    - **Model**: text-embedding-ada-002
    - **Model version**: *Use default version*
    - **Deployment type**: Standard
    - **Tokens per minute rate limit**: 5K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled

> \* A rate limit of 5,000 tokens per minute is more than adequate to complete this exercise while leaving capacity for other people using the same subscription.
    
## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

If you don't already have one, provision an Azure OpenAI resource in your Azure subscription.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure OpenAI** resource with the following settings:
    - **Subscription**: *Select the same Azure subscription that you used to create your Azure OpenAI resource*
    - **Resource group**: *The same resource group where you created your Azure OpenAI resource*
    - **Region**: *The same region where you created your Azure OpenAI resource*
    - **Name**: *A unique name of your choice*
    - **Pricing tier**: *Premium* or *Trial*

3. Select **Review + create** and wait for deployment to complete. Then go to the resource and launch the workspace.

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

## Install Required Libraries

1. In the Databricks workspace, go to the **Workspace** section.

2. Select **Create** and then select **Notebook**.

3. Name your notebook and select `Python` as the language.

4. In the first code cell, enter and run the following code to install the necessary libraries:
   
     ```python
    %pip install langchain openai langchain_openai faiss-cpu
     ```

5. After the installation is complete, restart the kernel in a new cell:

     ```python
    %restart_python
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
     
1. In a new cell, run the following code to generate embeddings using the `text-embedding-ada-002` model. Replace `your_openai_endpoint` and `your_openai_api_key` with your OpenAI endpoint and API key.

     ```python
    from langchain_openai import AzureOpenAIEmbeddings
     
    embedding_function = AzureOpenAIEmbeddings(
        deployment="text-embedding-ada-002",
        model="text-embedding-ada-002",
        azure_endpoint="your_openai_endpoint",
        openai_api_key="your_openai_api_key",
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

1. In a new cell, run the following code to create a QA system using the retriever and the `gpt-35-turbo-16k` model. Replace `your_openai_endpoint` and `your_openai_api_key` with your OpenAI endpoint and API key.
    
     ```python
    from langchain_openai import AzureChatOpenAI
    from langchain_core.prompts import ChatPromptTemplate
    from langchain.chains.combine_documents import create_stuff_documents_chain
    from langchain.chains import create_retrieval_chain
     
    llm = AzureChatOpenAI(
        deployment_name="gpt-35-turbo-16k",
        model_name="gpt-35-turbo-16k",
        azure_endpoint="your_openai_endpoint",
        api_version="2023-03-15-preview",
        openai_api_key="your_openai_api_key",
    )

    system_prompt = (
        "Use the given context to answer the question. "
        "If you don't know the answer, say you don't know. "
        "Use three sentences maximum and keep the answer concise. "
        "Context: {context}"
    )

    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("human", "{input}")
    ])

    qa_chain = create_stuff_documents_chain(llm, prompt)

    chain = create_retrieval_chain(retriever, qa_chain)
     ```

1. In a new cell, run the following code to test the QA system:

     ```python
    result = chain.invoke({"input": "What is Azure Databricks?"})
    print(result)
     ```

## Build an Image Generation Chain

Diffusion models such as DALL-E, Imagen, and Stable Diffusion, utilize deep learning techniques to generate images from textual descriptions, combining concepts, attributes, and styles in unique ways. The technology has been integrated into various frameworks and applications, allowing for creative and practical uses. Its development has been carefully managed to ensure responsible use, with safety measures in place to prevent the creation of harmful content.

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
