# Exercise 07 - Train a scalable Machine Learning Model using Azure Databricks
 
## Objective
Train a scalable machine learning model using Azure Databricks to predict customer churn based on a sample dataset.
 
### Step 1 - Set up Azure Databricks
- Log in to the Azure portal.
- Create an Azure Databricks workspace.
- Launch the workspace and create a new cluster with appropriate configurations for your workload (e.g., size, autoscaling, version).
 
### Step 2 - Upload Dataset to Azure Databricks
- Go to your Azure Databricks workspace.
- Navigate to the Data tab and upload your CSV dataset.
- Verify that the dataset is correctly uploaded and accessible.
 
### Step 3 - Explore Data and Preprocessing:
- Open a new notebook in Azure Databricks.
- Load the dataset into a DataFrame
 
```python
    df = spark.read.csv("/FileStore/tables/customer_churn.csv", header=True, inferSchema=True)
```
 
- Explore the data using descriptive statistics, histograms, and other visualizations to understand the features and their distributions.
- Preprocess the data as needed (e.g., handle missing values, encode categorical variables, scale numeric features).
 
### Step 4 - Split Data into Training and Test Sets:
- Split the dataset into training and test sets using a common ratio like 80:20
 
```python
    train_df, test_df = df.randomSplit([0.8, 0.2], seed=42)
```
 
### Step 5 - Choose a Machine Learning Algorithm:
- Select a machine learning algorithm suitable for binary classification tasks such as logistic regression, random forests, or gradient boosting.
 
### Step 6 - Train the Machine Learning Model:
- Import the necessary libraries and initialize the chosen algorithm
 
```python
    from pyspark.ml.classification import RandomForestClassifier
    # Initialize Random Forest classifier
    rf = RandomForestClassifier(featuresCol='features', labelCol='churn_status')
 
    #Fit the model on the training data
    model = rf.fit(train_df)
```
 
### Step 7 - Evaluate Model Performance:
- Make predictions on the test data using the trained model
 
```python
    predictions = model.transform(test_df)
```
 
- Evaluate the model's performance using metrics such as accuracy, precision, recall, and F1-score.
 
```python
    from pyspark.ml.evaluation import BinaryClassificationEvaluator
 
    evaluator = BinaryClassificationEvaluator(labelCol='churn_status')
    accuracy = evaluator.evaluate(predictions)
    print(f"Accuracy: {accuracy}")
```
 
### Step 8 - Optimize and Tune the Model (Optional):
- If desired, perform hyperparameter tuning and optimization using techniques like cross-validation or grid search to improve model performance.
 
### Step 9 - Save the Trained Model:
- Once satisfied with the model performance, save the trained model for future use or deployment.
 
```python
    model.save("/FileStore/models/customer_churn_model")
```
### Step 10 - Deployment (Optional):
- If you intend to deploy the model for production use, follow Azure Databricks' deployment guidelines or integrate the model into your desired application or pipeline.
### Step 11 - Cleanup (Optional):
- Clean up any unnecessary resources such as temporary dataframes, unused clusters, or files to optimize cost and workspace organization.
