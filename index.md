---
title: Online Hosted Instructions
permalink: index.html
layout: home
---

# Azure Databricks Exercises

These exercises are designed to support the following training content on Microsoft Learn:

- [Implement a data lakehouse analytics solution with Azure Databricks](https://learn.microsoft.com/training/paths/data-engineer-azure-databricks/)
- [Implement a machine learning solution with Azure Databricks](https://learn.microsoft.com/training/paths/build-operate-machine-learning-solutions-azure-databricks/)
- [Implement a data engineering solution with Azure Databricks](https://learn.microsoft.com/training/paths/azure-databricks-data-engineer/)
- [Implement Generative AI engineering with Azure Databricks](https://learn.microsoft.com/training/paths/implement-generative-ai-engineering-azure-databricks/)

You'll need an Azure subscription in which you have administrative access to complete these exercises.

{% assign exercises = site.pages | where_exp:"page", "page.url contains '/Instructions'" %}
{% for activity in exercises  %}
- [{{ activity.lab.title }}]({{ site.github.url }}{{ activity.url }}) |
{% endfor %}
