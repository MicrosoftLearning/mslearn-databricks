---
title: Online Hosted Instructions
permalink: index.html
layout: home
---

# Azure Databricks Exercises

These exercises are designed to support the following training content on Microsoft Learn:

- [Implement a Data Analytics Solution with Azure Databricks](https://learn.microsoft.com/training/paths/data-engineer-azure-databricks/)
- [Implement a Machine Learning solution with Azure Databricks](https://learn.microsoft.com/training/paths/build-operate-machine-learning-solutions-azure-databricks/)

You'll need an Azure subscription in which you have administrative access to complete these exercises.

{% assign exercises = site.pages | where_exp:"page", "page.url contains '/Instructions/Exercises'" %}
{% for activity in exercises  %}
- [{{ activity.lab.title }}]({{ site.github.url }}{{ activity.url }}) |
{% endfor %}