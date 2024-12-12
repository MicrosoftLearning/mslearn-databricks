---
lab:
    title: 'Use MLflow in Azure Databricks'
---

# Use MLflow in Azure Databricks

In this exercise, you'll explore to use use MLflow to train and serve machine learning models in Azure Databricks.

This exercise should take approximately **45** minutes to complete.

> **Note**: The Azure Databricks user interface is subject to continual improvement. The user interface may have changed since the instructions in this exercise were written.

## Before you start

You'll need an [Azure subscription](https://azure.microsoft.com/free) in which you have administrative-level access.

## Provision an Azure Databricks workspace

> **Note**: For this exercise, you need a **Premium** Azure Databricks workspace in a region where *model serving* is supported. See [Azure Databricks regions](https://learn.microsoft.com/azure/databricks/resources/supported-regions) for details of regional Azure Databricks capabilities. If you already have a *Premium* or *Trial* Azure Databricks workspace in a suitable region, you can skip this procedure and use your existing workspace.

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
7. Wait for the script to complete - this typically takes around 5 minutes, but in some cases may take longer. While you are waiting, review the [MLflow Guide](https://learn.microsoft.com/azure/databricks/mlflow/) article in the Azure Databricks documentation.

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
1. Change the default notebook name (**Untitled Notebook *[date]***) to **MLflow** and in the **Connect** drop-down list, select your cluster if it is not already selected. If the cluster is not running, it may take a minute or so to start.

## Ingest and prepare data

The scenario for this exercise is based on observations of penguins in Antarctica, with the goal of training a machine learning model to predict the species of an observed penguin based on its location and body measurements.

> **Citation**: The penguins dataset used in the this exercise is a subset of data collected and made available by [Dr. Kristen
Gorman](https://www.uaf.edu/cfos/people/faculty/detail/kristen-gorman.php)
and the [Palmer Station, Antarctica LTER](https://pal.lternet.edu/), a
member of the [Long Term Ecological Research
Network](https://lternet.edu/).

1. In the first cell of the notebook, enter the following code, which uses *shell* commands to download the penguin data from GitHub into the file system used by your cluster.

    ```bash
    %sh
    rm -r /dbfs/mlflow_lab
    mkdir /dbfs/mlflow_lab
    wget -O /dbfs/mlflow_lab/penguins.csv https://raw.githubusercontent.com/MicrosoftLearning/mslearn-databricks/main/data/penguins.csv
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
   
   data = spark.read.format("csv").option("header", "true").load("/mlflow_lab/penguins.csv")
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

## Run an MLflow experiment

MLflow enables you to run experiments that track the model training process and log evaluation metrics. This ability to record details of model training runs can be extremely useful in the iterative process of creating an effective machine learning model.

You can use the same libraries and techniques you normally use to train and evaluate a model (in this case, we'll use the Spark MLLib library), but do so within the context of an MLflow experiment that includes additional commands to log important metrics and information during the process.

1. Add a new cell and enter the following code in it:

    ```python
   import mlflow
   import mlflow.spark
   from pyspark.ml import Pipeline
   from pyspark.ml.feature import StringIndexer, VectorAssembler, MinMaxScaler
   from pyspark.ml.classification import LogisticRegression
   from pyspark.ml.evaluation import MulticlassClassificationEvaluator
   import time
   
   # Start an MLflow run
   with mlflow.start_run():
       catFeature = "Island"
       numFeatures = ["CulmenLength", "CulmenDepth", "FlipperLength", "BodyMass"]
     
       # parameters
       maxIterations = 5
       regularization = 0.5
   
       # Define the feature engineering and model steps
       catIndexer = StringIndexer(inputCol=catFeature, outputCol=catFeature + "Idx")
       numVector = VectorAssembler(inputCols=numFeatures, outputCol="numericFeatures")
       numScaler = MinMaxScaler(inputCol = numVector.getOutputCol(), outputCol="normalizedFeatures")
       featureVector = VectorAssembler(inputCols=["IslandIdx", "normalizedFeatures"], outputCol="Features")
       algo = LogisticRegression(labelCol="Species", featuresCol="Features", maxIter=maxIterations, regParam=regularization)
   
       # Chain the steps as stages in a pipeline
       pipeline = Pipeline(stages=[catIndexer, numVector, numScaler, featureVector, algo])
   
       # Log training parameter values
       print ("Training Logistic Regression model...")
       mlflow.log_param('maxIter', algo.getMaxIter())
       mlflow.log_param('regParam', algo.getRegParam())
       model = pipeline.fit(train)
      
       # Evaluate the model and log metrics
       prediction = model.transform(test)
       metrics = ["accuracy", "weightedRecall", "weightedPrecision"]
       for metric in metrics:
           evaluator = MulticlassClassificationEvaluator(labelCol="Species", predictionCol="prediction", metricName=metric)
           metricValue = evaluator.evaluate(prediction)
           print("%s: %s" % (metric, metricValue))
           mlflow.log_metric(metric, metricValue)
   
           
       # Log the model itself
       unique_model_name = "classifier-" + str(time.time())
       mlflow.spark.log_model(model, unique_model_name, mlflow.spark.get_default_conda_env())
       modelpath = "/model/%s" % (unique_model_name)
       mlflow.spark.save_model(model, modelpath)
       
       print("Experiment run complete.")
    ```

1. When the experiment run has finished, under the code cell, if necessary use the **&#9656;** toggle to expand the **MLflow run** details. The use the **experiment** hyperlink that is displayed there to open the MLflow page that lists your experiment runs. Each run is assigned a unique name.
1. Select the most recent run and view its details. Note that you can expand sections to see the **Parameters** and **Metrics** that were logged, and you can see details of the model that was trained and saved.

    > **Tip**: You can also use the **MLflow experiments** icon in the sidebar menu on the right of this notebook to view details of experiment runs.

## Create a function

In machine learning projects, data scientists often try training models with different parameters, logging the results each time. To accomplish that, it's common to create a function that encapsulates the training process and call it with the parameters you want to try.

1. In a new cell, run the following code to create a function based on the training code you used previously:

    ```python
   def train_penguin_model(training_data, test_data, maxIterations, regularization):
       import mlflow
       import mlflow.spark
       from pyspark.ml import Pipeline
       from pyspark.ml.feature import StringIndexer, VectorAssembler, MinMaxScaler
       from pyspark.ml.classification import LogisticRegression
       from pyspark.ml.evaluation import MulticlassClassificationEvaluator
       import time
   
       # Start an MLflow run
       with mlflow.start_run():
   
           catFeature = "Island"
           numFeatures = ["CulmenLength", "CulmenDepth", "FlipperLength", "BodyMass"]
   
           # Define the feature engineering and model steps
           catIndexer = StringIndexer(inputCol=catFeature, outputCol=catFeature + "Idx")
           numVector = VectorAssembler(inputCols=numFeatures, outputCol="numericFeatures")
           numScaler = MinMaxScaler(inputCol = numVector.getOutputCol(), outputCol="normalizedFeatures")
           featureVector = VectorAssembler(inputCols=["IslandIdx", "normalizedFeatures"], outputCol="Features")
           algo = LogisticRegression(labelCol="Species", featuresCol="Features", maxIter=maxIterations, regParam=regularization)
   
           # Chain the steps as stages in a pipeline
           pipeline = Pipeline(stages=[catIndexer, numVector, numScaler, featureVector, algo])
   
           # Log training parameter values
           print ("Training Logistic Regression model...")
           mlflow.log_param('maxIter', algo.getMaxIter())
           mlflow.log_param('regParam', algo.getRegParam())
           model = pipeline.fit(training_data)
   
           # Evaluate the model and log metrics
           prediction = model.transform(test_data)
           metrics = ["accuracy", "weightedRecall", "weightedPrecision"]
           for metric in metrics:
               evaluator = MulticlassClassificationEvaluator(labelCol="Species", predictionCol="prediction", metricName=metric)
               metricValue = evaluator.evaluate(prediction)
               print("%s: %s" % (metric, metricValue))
               mlflow.log_metric(metric, metricValue)
   
   
           # Log the model itself
           unique_model_name = "classifier-" + str(time.time())
           mlflow.spark.log_model(model, unique_model_name, mlflow.spark.get_default_conda_env())
           modelpath = "/model/%s" % (unique_model_name)
           mlflow.spark.save_model(model, modelpath)
   
           print("Experiment run complete.")
    ```

1. In a new cell, use the following code to call your function:

    ```python
   train_penguin_model(train, test, 10, 0.2)
    ```

1. View the details of the MLflow experiment for the second run.

## Register and deploy a model with MLflow

In addition to tracking details of training experiment runs, you can use MLflow to manage the machine learning models you've trained. You've already logged the model trained by each experiment run. You can also *register* models and deploy them so they can be served to client applications.

> **Note**: Model serving is only supported in Azure Databricks *Premium* workspaces, and is restricted to [certain regions](https://learn.microsoft.com/azure/databricks/resources/supported-regions).

1. View the details page for the most recent experiment run.
1. Use the **Register Model** button to register the model that was logged in that experiment and when prompted, create a new model named **Penguin Predictor**.
1. When the model has been registered, view the **Models** page (in the navigation bar on the left) and select the **Penguin Predictor** model.
1. In the page for the **Penguin Predictor** model, use the **Use model for inference** button to create a new real-time endpoint with the following settings:
    - **Model**: Penguin Predictor
    - **Model version**: 1
    - **Endpoint**: predict-penguin
    - **Compute size**: Small

    The serving endpoint is hosted in a new cluster, which it may take several minutes to create.
  
1. When the endpoint has been created, use the **Query endpoint** button at the top right to open an interface from which you can test the endpoint. Then in the test interface, on the **Browser** tab, enter the following JSON request and use the **Send Request** button to call the endpoint and generate a prediction.

    ```json
    {
      "dataframe_records": [
      {
         "Island": "Biscoe",
         "CulmenLength": 48.7,
         "CulmenDepth": 14.1,
         "FlipperLength": 210,
         "BodyMass": 4450
      }
      ]
    }
    ```

1. Experiment with a few different values for the penguin features and observe the results that are returned. Then, close the test interface.

## Delete the endpoint

When the endpoint is not longer required, you should delete it to avoid unnecessary costs.

In the **predict-penguin** endpoint page, in the **&#8285;** menu, select **Delete**.

## Clean up

In Azure Databricks portal, on the **Compute** page, select your cluster and select **&#9632; Terminate** to shut it down.

If you've finished exploring Azure Databricks, you can delete the resources you've created to avoid unnecessary Azure costs and free up capacity in your subscription.

> **More information**: For more information see the [Spark MLLib documentation](https://spark.apache.org/docs/latest/ml-guide.html).
