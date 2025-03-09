---
title: "[Spring JPA] Spring Data JPA는 기존 JPA와 뭐가 다를까?"
date: 2025-01-31 23:18:07 +0900
categories:
  - Backend
  - Spring
tags:
  - Spring
  - Database
  - JPA
  - Java
excerpt_separator: <!-- more -->
draft: true
---

<!-- 요약 적기 -->

Spring Data JPA 는 일반 JPA와 무엇이 다를까? `Spring Data JPA` 를 사용하면 보다 편리하게 리포지토리 코드를 생성하거나 사용할 수 있다.

<!-- more -->

## 


## Custom Method 정의하기

`interface` 에서 커스텀 메서드를 정의하면 형식에 맞춰서 어느정도는 구현하지 않아도 알아서 구현해준다.

`findBy` 를 예시로 들어보자. `PK` 가 아닌 다른 값으로도 검색을 하고 싶을 것이다.

그때, 