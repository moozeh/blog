---
title: Spring Stereotype 어노테이션들에 대해 알아보자
date: 2025-01-25T16:58:09+09:00
tags:
  - Spring
categories:
  - Spring
image: /assets/img/template_spring-20250130224900580.webp
---
<!-- truncate -->

## @Component

기본적으로 스프링의 `@Bean` 을 나타내며, 범용적으로 사용된다.

모든 스프링의 `Stereotype Annotation` 의 토대가 된다.
## @Service

비즈니스 로직을 표시할 때 사용되는 `@Component`이다.

클래스에 특정 비즈니스 로직을 작성했다면, 이 어노테이션을 사용하자!

```java
@Service
public class BusinessCalculationService {
    private final DataService dataService; // write access modifier every time.

    public BusinessCalculationService(DataService dataService) {
        this.dataService = dataService;
    }

    public int findMax() {
        return Arrays.stream(dataService.retrieveData()).max().orElse(0);
    }
}
```

## @Controller

REST API 에서 컨트롤러를 정의하는데 쓰인다.

## @Repository

어떤 `Bean` 이 데이터 베이스 내 데이터를 조작하는 경우, `@Repository` 라고 표시하여 이를 알릴 수 있다.

`MongoDBService` 의 목적이 **데이터베이스와 통신하여 데이터를 조작하는 것**이 목적임을 이를 알려주는 것이다.

```java
@Repository
@Primary
public class MongoDbDataService implements DataService {
    @Override
    public int[] retrieveData() {
        return new int[] {1, 2, 3};
    }
}
```

## 그 외

실제로 `@Component` 이외에도 이렇게 따로 정의된 어노테이션이 많다는 것이다.

최대한 구체적인 어노테이션을 쓰는 게 좋다.

그 이유는, 각각의 클래스가 **어떤 역할을 하는지 명시하여 내가 어떤 의도를 가지고 했는지 알려줄 수 있기 때문이다.**
즉, 정보가 추가되는 것이다.

나중에 `AOP` 를 사용하여 부가적인 동작을 내려줄 수 있다.

예를들어, `@Repository` 어노테이션이 있다면 이후에 `JDBC` 예외 변환이 가능하다.
