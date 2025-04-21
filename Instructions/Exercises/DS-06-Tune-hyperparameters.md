---
lab:
    title: 'Optimize Hyperparameters for machine learning in Azure Databricks'
---

# Optimize Hyperparameters for machine learning in Azure Databricks

In this exercise, you'll use the **Optuna** library to optimize hyperparameters for machine learning model training in Azure Databricks.

This exercise should take approximately **30** minutes to complete.

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

    ```
    rm -r mslearn-databricks -f
    git clone https://github.com/MicrosoftLearning/mslearn-databricks
    ```

5. After the repo has been cloned, enter the following command to run the **setup.ps1** script, which provisions an Azure Databricks workspace in an available region:

    ```
    ./mslearn-databricks/setup.ps1
    ```

6. If prompted, choose which subscription you want to use (this will only happen if you have access to multiple Azure subscriptions).
7. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer. While you are waiting, review the [Hyperparameter tuning](https://learn.microsoft.com/azure/databricks/machine-learning/automl-hyperparam-tuning/) article in the Azure Databricks documentation.

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
    - **Node type**: Standard_D4ds_v5
    - **Terminate after** *20* **minutes of inactivity**

1. Wait for the cluster to be created. It may take a minute or two.

> **Note**: If your cluster fails to start, your subscription may have insufficient quota in the region where your Azure Databricks workspace is provisioned. See [CPU core limit prevents cluster creation](https://docs.microsoft.com/azure/databricks/kb/clusters/azure-core-limit) for details. If this happens, you can try deleting your workspace and creating a new one in a different region. You can specify a region as a parameter for the setup script like this: `./mslearn-databricks/setup.ps1 eastus`

## Create a notebook

You're going to run code that uses the Spark MLLib library to train a machine learning model, so the first step is to create a new notebook in your workspace.

1. In the sidebar, use the **(+) New** link to create a **Notebook**.
1. Change the default notebook name (**Untitled Notebook *[date]***) to **Hyperparameter Tuning** and in the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

## Ingest data

The scenario for this exercise is based on observations of penguins in Antarctica, with the goal of training a machine learning model to predict the species of an observed penguin based on its location and body measurements.

> **Citation**: The penguins dataset used in the this exercise is a subset of data collected and made available by [Dr. Kristen
Gorman](https://www.uaf.edu/cfos/people/faculty/detail/kristen-gorman.php)
and the [Palmer Station, Antarctica LTER](https://pal.lternet.edu/), a
member of the [Long Term Ecological Research
Network](https://lternet.edu/).

1. In the first cell of the notebook, enter the following code, which uses *shell* commands to download the penguin data from GitHub into the file system used by your cluster.

    ```bash
    %sh
    rm -r /dbfs/hyperparam_tune_lab
    mkdir /dbfs/hyperparam_tune_lab
    wget -O /dbfs/hyperparam_tune_lab/penguins.csv https://raw.githubusercontent.com/MicrosoftLearning/mslearn-databricks/main/data/penguins.csv
    ```

1. Use the **&#9656; Run Cell** menu option at the left of the cell to run it. Then wait for the Spark job run by the code to complete.
1. Now prepare the data for machine learning. Under the existing code cell, use the **+** icon to add a new code cell. Then in the new cell, enter and run the following code to:
    - Remove any incomplete rows
    - Apply appropriate data types
    - View a random sample of the data
    - Split the data into two datasets: one for training, and another for testing.


    ```python
   from pyspark.sql.types import *
   from pyspark.sql.functions import *
   
   data = spark.read.format("csv").option("header", "true").load("/hyperparam_tune_lab/penguins.csv")
   data = data.dropna().select(col("Island").astype("string"),
                             col("CulmenLength").astype("float"),
                             col("CulmenDepth").astype("float"),
                             col("FlipperLength").astype("float"),
                             col("BodyMass").astype("float"),
                             col("Species").astype("int")
                             )
   display(data.sample(0.2))
   
   splits = data.randomSplit([0.7, 0.3])
   train = splits[0]
   test = splits[1]
   print ("Training Rows:", train.count(), " Testing Rows:", test.count())
    ```

## Optimize hyperparameter values for training a model

You train a machine learning model by fitting the features to an algorithm that calculates the most probable label. Algorithms take the training data as a parameter and attempt to calculate a mathematical relationship between the features and labels. In addition to the data, most algorithms use one or more *hyperparameters* to influence the way the relationship is calculated; and determining the optimal hyperparameter values is an important part of the iterative model training process.

To help you determine optimal hyperparameter values, Azure Databricks includes support for [**Optuna**](https://optuna.readthedocs.io/en/stable/index.html) - a library that enables you to try multiple hyperparameter values and find the best combination for your data.

The first step in using Optuna is to create a function that:

- Trains a model using one or more hyperparameter values that are passed to the function as parameters.
- Calculates a performance metric that can be used to measure *loss* (how far the model is from perfect prediction performance)
- Returns the loss value so can be optimized (minimized) iteratively by trying different hyperparameter values

1. Add a new cell and use the following code to create a function that defines the range of values to be used for the hyperparameters and uses the penguin data to train a classification model that predicts the species of a penguin based on its location and measurements:

    ```python
   import optuna
   import mlflow # if you wish to log your experiments
   from pyspark.ml import Pipeline
   from pyspark.ml.feature import StringIndexer, VectorAssembler, MinMaxScaler
   from pyspark.ml.classification import DecisionTreeClassifier
   from pyspark.ml.evaluation import MulticlassClassificationEvaluator
   
   def objective(trial):
       # Suggest hyperparameter values (maxDepth and maxBins):
       max_depth = trial.suggest_int("MaxDepth", 0, 9)
       max_bins = trial.suggest_categorical("MaxBins", [10, 20, 30])

       # Define pipeline components
       cat_feature = "Island"
       num_features = ["CulmenLength", "CulmenDepth", "FlipperLength", "BodyMass"]
       catIndexer = StringIndexer(inputCol=cat_feature, outputCol=cat_feature + "Idx")
       numVector = VectorAssembler(inputCols=num_features, outputCol="numericFeatures")
       numScaler = MinMaxScaler(inputCol=numVector.getOutputCol(), outputCol="normalizedFeatures")
       featureVector = VectorAssembler(inputCols=[cat_feature + "Idx", "normalizedFeatures"], outputCol="Features")

       dt = DecisionTreeClassifier(
           labelCol="Species",
           featuresCol="Features",
           maxDepth=max_depth,
           maxBins=max_bins
       )

       pipeline = Pipeline(stages=[catIndexer, numVector, numScaler, featureVector, dt])
       model = pipeline.fit(train)

       # Evaluate the model using accuracy.
       predictions = model.transform(test)
       evaluator = MulticlassClassificationEvaluator(
           labelCol="Species",
           predictionCol="prediction",
           metricName="accuracy"
       )
       accuracy = evaluator.evaluate(predictions)

       # Since Optuna minimizes the objective, return negative accuracy.
       return -accuracy
    ```

1. Add a new cell and use the following code to run the optimization experiment:

    ```python
   # Optimization run with 5 trials:
   study = optuna.create_study()
   study.optimize(objective, n_trials=5)

   print("Best param values from the optimization run:")
   print(study.best_params)
    ```

1. Observe as the code iteratively runs the training function 5 times while trying to minimize the loss(based on the **n_trials** setting). Each trial is recorded by MLflow, and you can use the the **&#9656;** toggle to expand the **MLflow run** output under the code cell and select the **experiment** hyperlink to view them. Each run is assigned a random name, and you can view each of them in the MLflow run viewer to see details of parameters and metrics that were recorded.
1. When all of the runs have finished, observe that the code displays details of the best hyperparameter values that were found (the combination that resulted in the least loss). In this case, the **MaxBins** parameter is defined as a choice from a list of three possible values (10, 20, and 30) - the best value indicates the zero-based item in the list (so 0=10, 1=20, and 2=30). The **MaxDepth** parameter is defined as a random integer between 0 and 10, and the integer value that gave the best result is displayed. 

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.

> **More information**: For more information see [Hyperparameter tuning](https://learn.microsoft.com/azure/databricks/machine-learning/automl-hyperparam-tuning/) in the Azure Databricks documentation.
