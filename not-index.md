--- 
layout: default 
---
{{ site.title }}

{% if site.subtitle %}
{{ site.subtitle }}

{% endif %}
{% for post in paginator.posts %}
{{ post.title }}

{{ post.content | strip_html | truncatewords: 50 }}

{{ post.date | date: "%B %-d, %Y" }}
{% if post.categories %}in {% for cat in post.categories %} {% if site.jekyll-archives %} {{ cat | capitalize }}{% if forloop.last == false %}, {% endif %} {% else %} {{ cat | capitalize }}{% if forloop.last == false %}, {% endif %} {% endif %} {% endfor %}{% endif %}
{% if forloop.last == false %}
{% endif %} {% endfor %}
{% if paginator.next_page %} {% else %} {% endif %} Page {{ paginator.page }} of {{ paginator.total_pages }} {% if paginator.previous_page %} {% if paginator.page == 2 %} {% else %} {% endif %} {% else %} {% endif %}

View All Posts by Category
