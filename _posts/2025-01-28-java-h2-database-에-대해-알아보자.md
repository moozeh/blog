---
title: "[Java] H2 Database 에 대해 알아보자"
date: 2025-01-28T18:04:20+09:00
tags: [Java, Database, Spring]
categories: [Java]
draft: true
---
<!-- truncate -->

H2 Database 는 Spring Starter 사이트에서 사용되는 인메모리 데이터베이스이다. 이에 대해 자세히 알아보도록 하자!

## H2 Database 란

H2 데이터베이스는 `Spring Initializer` 에서 기본적으로 제공되는 스프링 인메모리 데이터베이스 라이브러리이다.



### SQLite 와의 차이점

유명한 인메모리 데이터베이스 `SQLite` 와 큰 차이가 무엇인지 궁금할 것이다.

## H2 Database 기능

### h2-console

![](/assets/img/Pasted%20image%2020250128230234.png)

![](/assets/img/Pasted%20image%2020250128230748.png)

![](/assets/img/Pasted%20image%2020250128230800.png)

### H2 에 Database Schema 생성해보기

인메모리 **Database** 이므로 결국 테이블이 필요하다. 하지만, 시작할 때 매번 설정해주어야할까?

H2 에 시작할 때마다 테이블을 새로 구조화해주기 위해선 `.sql` 파일을 리소스에 넣어두면 된다.


> [!note]
> 
> `Spring Data JPA Starter` 에서는 `resources/schema.sql` 파일에서 자동으로 스키마를 불러와서 대응되는 데이터베이스에 저장해줍니다.



![](/assets/img/Pasted%20image%2020250128231616.png)

성공적으로 저장된 모습을 볼 수 있다.

이제부터 `JPA`, 혹은 `JDBC` 등을 통해 앞서 언급한 해당되는 `url`로 쿼리문을 실행하면 된다. 마치 `RDB` 를 사용하는 것과 같은 느낌이다.
