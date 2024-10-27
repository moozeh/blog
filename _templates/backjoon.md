<%*
// 사용자 입력 받기
const problemId = await tp.system.prompt("백준 문제 번호를 입력해주세요.");
const problemTitle = await tp.system.prompt("백준 문제 제목을 입력해주세요.");
const solvedLang = await tp.system.prompt("문제 해결 시 사용한 언어를 입력해주세요.");

// 파일명 생성 및 변경
const fileName = tp.date.now("YYYY-MM-DD") + "-" + problemId + "-" + problemTitle.toLowerCase().replace(/\[|\]|\:|\./g, '').replace(/\s+/g, '-');
await tp.file.rename(fileName);

-%>
---
title: <% `"[ 백준 ${problemId} ] ${problemTitle} : ${solvedLang} 풀이"` %>
date: <% tp.date.now("YYYY-MM-DD HH:mm:ss") %> +0900
categories: [Backjoon]
tags: [ps]
image: /assets/img/backjoon-thumbnail.webp
---

## 문제 링크

- [이동하기!](<% `https://boj.kr/${problemId}` %>)

---

## 해결 과정


## 소스 코드

```cpp
```
