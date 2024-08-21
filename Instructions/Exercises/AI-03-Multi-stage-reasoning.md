---
lab:
    title: 'Multi-stage Reasoning with LangChain using Azure Databricks and GPT-4'
---

# Multi-stage Reasoning with LangChain using Azure Databricks and GPT-4

Multi-stage reasoning is a cutting-edge approach in AI that involves breaking down complex problems into smaller, more manageable stages. LangChain, a software framework, facilitates the creation of applications that leverage large language models (LLMs) like GPT-4. When integrated with Azure Databricks, LangChain allows for seamless data loading, model wrapping, and the development of sophisticated AI agents. This combination is particularly powerful for handling intricate tasks that require a deep understanding of context and the ability to reason across multiple steps.

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

5. Copy one of the available keys as you will use it in this exercise.

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

5. After the repo has been cloned, enter the following command and replace `region` with the same region where you created your OpenAI resource. This command will run the **setup.ps1** script, which provisions an Azure Databricks workspace in the specified region:

     ```powershell
    ./mslearn-databricks/setup.ps1 region
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
