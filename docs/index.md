---
layout: home
---

{% assign books = site.data.books | sort:"created" |reverse %}
<div class="books box">
  {%- for book in books -%}
  {%- if book.assetid -%}
  {% assign booktitle = book.title |replace: '"', "" |split: " (" | first |split: ","|first|split: ":" |first %}
  <div class="book flex column" data-count="{{book.count}}" data-modified="{{book.modified | date: "%F" }}" data-created="{{book.created | date: "%F" }}">
    <a href="{{ site.baseurl }}/{{ book.slug }}">
      <img src="{{ site.baseurl }}/{{book.cover}}" alt="{{booktitle}}">
      <label>
        <strong class="book-item-title">{{booktitle}}</strong>
        <span class="book-item-author">by {{book.author}}</span>
      </label>
    </a>
  </div>
  {%- endif -%}
  {%- endfor -%}
</div>
