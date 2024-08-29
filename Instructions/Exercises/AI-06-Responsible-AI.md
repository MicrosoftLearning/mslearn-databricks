---
lab:
    title: 'Responsible AI with Large Language Models using Azure Databricks and Azure OpenAI'
---

# Responsible AI with Large Language Models using Azure Databricks and Azure OpenAI

Integrating Large Language Models (LLMs) into Azure Databricks and Azure OpenAI offers a powerful platform for responsible AI development. These sophisticated transformer-based models excel in natural language processing tasks, enabling developers to innovate rapidly while adhering to principles of fairness, reliability, safety, privacy, security, inclusiveness, transparency, and accountability. 

This lab will take approximately **20** minutes to complete.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Provision an Azure OpenAI resource

If you don't already have one, provision an Azure OpenAI resource in your Azure subscription.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure OpenAI** resource with the following settings:
    - **Subscription**: *Select an Azure subscription that has been approved for access to the Azure OpenAI service*
    - **Resource group**: *Choose or create a resource group*
    - **Region**: *Make a **random** choice from any of the following regions*\*
        - East US 2
        - North Central US
        - Sweden Central
        - Switzerland West
    - **Name**: *A unique name of your choice*
    - **Pricing tier**: Standard S0

> \* Azure OpenAI resources are constrained by regional quotas. The listed regions include default quota for the model type(s) used in this exercise. Randomly choosing a region reduces the risk of a single region reaching its quota limit in scenarios where you are sharing a subscription with other users. In the event of a quota limit being reached later in the exercise, there's a possibility you may need to create another resource in a different region.

3. Wait for deployment to complete. Then go to the deployed Azure OpenAI resource in the Azure portal.

4. In the left pane, under **Resource Management**, select **Keys and Endpoint**.

5. Copy the endpoint and one of the available keys as you will use it later in this exercise.

## Deploy the required model

Azure provides a web-based portal named **Azure AI Studio**, that you can use to deploy, manage, and explore models. You'll start your exploration of Azure OpenAI by using Azure AI Studio to deploy a model.

> **Note**: As you use Azure AI Studio, message boxes suggesting tasks for you to perform may be displayed. You can close these and follow the steps in this exercise.

1. In the Azure portal, on the **Overview** page for your Azure OpenAI resource, scroll down to the **Get Started** section and select the button to go to **Azure AI Studio**.
   
1. In Azure AI Studio, in the pane on the left, select the **Deployments** page and view your existing model deployments. If you don't already have one, create a new deployment of the **gpt-35-turbo** model with the following settings:
    - **Deployment name**: *gpt-35-turbo*
    - **Model**: gpt-35-turbo
    - **Model version**: Default
    - **Deployment type**: Standard
    - **Tokens per minute rate limit**: 5K\*
    - **Content filter**: Default
    - **Enable dynamic quota**: Disabled
    
> \* A rate limit of 5,000 tokens per minute is more than adequate to complete this exercise while leaving capacity for other people using the same subscription.

## Provision an Azure Databricks workspace

> **Tip**: If you already have an Azure Databricks workspace, you can skip this procedure and use your existing workspace.

1. Sign into the **Azure portal** at `https://portal.azure.com`.
2. Create an **Azure Databricks** resource with the following settings:
    - **Subscription**: *Select the same Azure subscription that you used to create your Azure OpenAI resource*
    - **Resource group**: *The same resource group where you created your Azure OpenAI resource*
    - **Region**: *The same region where you created your Azure OpenAI resource*
    - **Name**: *A unique name of your choice*
    - **Pricing tier**: *Premium* or *Trial*

3. Select **Review + create** and wait for deployment to complete. Then go to the resource and launch the workspace.

## Create a cluster

Azure Databricks is a distributed processing platform that uses Apache Spark *clusters* to process data in parallel on multiple nodes. Each cluster consists of a driver node to coordinate the work, and worker nodes to perform processing tasks. In this exercise, you'll create a *single-node* cluster to minimize the compute resources used in the lab environment (in which resources may be constrained). In a production environment, you'd typically create a cluster with multiple worker nodes.

> **Tip**: If you already have a cluster with a 13.3 LTS **<u>ML</u>** or higher runtime version in your Azure Databricks workspace, you can use it to complete this exercise and skip this procedure.

1. In the Azure portal, browse to the resource group where the Azure Databricks workspace was created.
2. Select your Azure Databricks Service resource.
3. In the **Overview** page for your workspace, use the **Launch Workspace** button to open your Azure Databricks workspace in a new browser tab; signing in if prompted.

> **Tip**: As you use the Databricks Workspace portal, various tips and notifications may be displayed. Dismiss these and follow the instructions provided to complete the tasks in this exercise.

4. In the sidebar on the left, select the **(+) New** task, and then select **Cluster**.
5. In the **New Cluster** page, create a new cluster with the following settings:
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

6. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region.

## Install required libraries

1. In your cluster's page, select the **Libraries** tab.

2. Select **Install New**.

3. Select **PyPI** as the library source and install `openai==1.42.0`.

## Create a new notebook

1. In the sidebar, use the **(+) New** link to create a **Notebook**.
   
1. Name your notebook and in the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

1. In the first cell of the notebook, run the following code with the access information you copied at the beginning of this exercise to assign persistent environment variables for authentication when using Azure OpenAI resources:

     ```python
    import os

    os.environ["AZURE_OPENAI_API_KEY"] = "your_openai_api_key"
    os.environ["AZURE_OPENAI_ENDPOINT"] = "your_openai_endpoint"
    os.environ["AZURE_OPENAI_API_VERSION"] = "2023-03-15-preview"
     ```

1. In a new cell, run a simple query to verify the integration with Azure OpenAI resource:

     ```python
    import os
    from openai import AzureOpenAI

    client = AzureOpenAI(
       azure_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT"),
       api_key = os.getenv("AZURE_OPENAI_API_KEY"),
       api_version = os.getenv("AZURE_OPENAI_API_VERSION")
    )

    system_prompt = "Please answer the following question in informal language."

    response = client.chat.completions.create(
               model="gpt-35-turbo",
               messages=[
                   {"role": "system", "content": system_prompt},
                   {"role": "user", "content": "What is responsible AI?"},
               ],
               max_tokens=100
               )

    print(response.choices[0].message.content)
     ```

## Implement Responsible AI Practices

Responsible AI refers to the ethical and sustainable development, deployment, and use of artificial intelligence systems. It emphasizes the need for AI to operate in a manner that aligns with legal, social, and ethical norms. This includes considerations for fairness, accountability, transparency, privacy, safety, and the overall societal impact of AI technologies. Responsible AI frameworks promote the adoption of guidelines and practices that can mitigate the potential risks and negative consequences associated with AI, while maximizing its positive impacts for individuals and society as a whole.

### Bias Detection and Mitigation

1. Create a notebook cell to test for potential biases in the GPT-4 model's responses. For example, you can prompt the model with neutral and loaded questions, comparing the outputs.

    2. Implement strategies for bias mitigation, such as prompt engineering and post-processing of model outputs.

    ```python
    neutral_prompt = "Describe a leader."
    loaded_prompt = "Describe a female leader."

    neutral_response = openai.Completion.create(engine="gpt-4", prompt=neutral_prompt, max_tokens=100)
    loaded_response = openai.Completion.create(engine="gpt-4", prompt=loaded_prompt, max_tokens=100)

    print("Neutral Response:", neutral_response.choices[0].text.strip())
    print("Loaded Response:", loaded_response.choices[0].text.strip())
    ```

- Fairness and Transparency

    1. Create logging mechanisms to track and explain the decisions made by the model.
    2. Implement a method to interpret and explain the outputs, such as through SHAP (SHapley Additive exPlanations) or other interpretability tools.

    ```python
    # Example: Log model outputs for later analysis
    import logging

    logging.basicConfig(filename='gpt4_outputs.log', level=logging.INFO)

    logging.info("Neutral Prompt Response: " + neutral_response.choices[0].text.strip())
    logging.info("Loaded Prompt Response: " + loaded_response.choices[0].text.strip())
    ```

- Hallucination Detection

    1. Analyze outputs to detect hallucinations (i.e., when the model generates incorrect or nonsensical information).
    2. Implement validation checks by cross-referencing with external reliable sources.

    ```python
    prompt = "Give a detailed history of the event that never happened."
    response = openai.Completion.create(engine="gpt-4", prompt=prompt, max_tokens=200)

    print(response.choices[0].text.strip())
    # Cross-reference with trusted data sources to validate the information
    ```

## Step 6: Evaluation and Continuous Improvement

- Model Evaluation
    1. Evaluate the model's performance on key metrics like fairness, accuracy, and relevance.
    2. Create custom evaluation metrics if needed, focusing on responsible AI aspects.

- Continuous Monitoring
    1. Set up dashboards in Databricks to monitor the model's behavior over time.
    2. Implement alerts for any deviations from expected behavior that could indicate bias, hallucinations, or other issues.

    ```python
    # Example: Plotting response times or biases over time
    import matplotlib.pyplot as plt

    # Sample data
    times = [1, 2, 3, 4]
    biases = [0.1, 0.2, 0.15, 0.1]

    plt.plot(times, biases)
    plt.xlabel('Time')
    plt.ylabel('Bias Score')
    plt.title('Bias Over Time')
    plt.show()
    ```

## Step 7: Reporting and Documentation
- Create Responsible AI Documentation
    1. Document the steps taken to ensure responsible AI in your project, including any bias mitigation strategies, fairness assessments, and transparency mechanisms.

- Prepare a Summary Report
    1. Summarize the findings, including the effectiveness of the responsible AI strategies implemented.
    2. Provide recommendations for further improvements.

## Step 8: Clean Up Resources
- Terminate the Cluster:
    1. Go back to the "Compute" page, select your cluster, and click "Terminate" to stop the cluster.

- Optional: Delete the Databricks Service:
    1. To avoid incurring further charges, consider deleting the Databricks workspace if this lab is not part of a larger project or learning path.

By completing this exercise, you have successfully implemented responsible AI practices in developing and deploying Large Language Models using Azure Databricks and GPT-4. These practices will help you build AI systems that are fair, transparent, and aligned with ethical guidelines.
