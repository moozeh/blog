<%*
// 사용자 입력 받기
const title = await tp.system.prompt("제목을 입력하세요");
const categories = await tp.system.prompt("카테고리를 입력하세요 (쉼표로 구분)");
const tags = await tp.system.prompt("태그를 입력하세요 (쉼표로 구분)");

// 파일명 생성 및 변경
const fileName = tp.date.now("YYYY-MM-DD") + "-" + title.toLowerCase().replace(/\[|\]|\:|\./g, '').replace(/\s+/g, '-');
await tp.file.rename(fileName);

// 카테고리와 태그 배열로 변환
const categoryArray = categories.split(",").map(item => item.replace(/\s|\./g, '').trim());
const tagArray = tags.split(",").map(item => item.replace(/\s|\./g, '').trim());
-%>
---
title: <% `"${title}"` %>
date: <% tp.date.now("YYYY-MM-DD HH:mm:ss") %> +0900
categories: [<% categoryArray.join(", ") %>]
tags: [<% tagArray.join(", ") %>]
---
