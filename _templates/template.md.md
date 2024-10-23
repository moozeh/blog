---
title: <% title %>
date: <% tp.date.now("YYYY-MM-DD HH:mm:ss") %> +0900
categories: 
tags: 
image:
---

<%*
const title = await tp.system.prompt("제목을 입력하세요");
const fileName = tp.date.now("YYYY-MM-DD") + "-" + title.toLowerCase().replace(/\s+/g, '-');
await tp.file.rename(fileName);
await tp.title.rename(title);
-%>