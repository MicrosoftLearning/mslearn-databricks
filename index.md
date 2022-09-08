---
title: Online Hosted Instructions
permalink: index.html
layout: home
---

# Azure Databricks Exercises

These hands-on exercises are designed to support training content on [Microsoft Learn](https://docs.microsoft.com/training/paths/data-engineer-azure-databricks/).

You'll need an Azure subscription in which you have administrative access to complete these exercises.

{% assign labs = site.pages | where_exp:"page", "page.url contains '/Instructions/Labs'" %}
| Exercise |
| --- | --- | 
{% for activity in labs  %}| [{{ activity.lab.title }}{% if activity.lab.type %} - {{ activity.lab.type }}{% endif %}]({{ site.github.url }}{{ activity.url }}) |
{% endfor %}

