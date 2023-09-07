---
layout: home
---

{%- include svg-definitions.html -%}
{%- assign books = site.data.books | sort: "created" | reverse -%}

<div class="books box">
  {%- for book in books -%}
    {% assign title = book.title | replace: '"', "" | split: " (" | first | split: "," | first | split: ":" | first %}
    <div
      class="book"
      data-count="{{book.count}}"
      data-modified="{{book.modified | date: "%F" }}"
      data-created="{{book.created | date: "%F" }}">
      <div class="count">
        <svg width="14" height="14">
          <use href="#chat-square-text"></use>
        </svg>
        <span>{{ book.count }}</span>
      </div>
      <a href="{{ site.baseurl }}/{{ book.slug }}">
        <img src="https://raw.githubusercontent.com/nntrn/bookstand/main/docs/assets/artwork/{{book.assetid}}.jpg" alt="{{title}}">
        <label>
          <strong class="book-item-title">{{ title }}</strong>
          <span class="book-item-author">by {{ book.author }}</span>
        </label>
      </a>
    </div>
  {%- endfor -%}
</div>