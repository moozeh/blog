---
title: "[Spring] Spring JDBC의 특징"
date: 2025-01-29T13:35:24+09:00
tags:
  - Spring
  - Database
  - JDBC
categories:
  - Backend
  - Spring
image: /assets/img/template_spring-20250130224900580.webp
---
<!-- truncate -->

마인크래프트 플러그인을 만들면서 기존 `JDBC` 를 썼다. 그런데, `Spring JDBC` 와는 무슨 차이일까. 그 차이점을 알아보자.

## JDBC란

JDBC는 1997년 Sun Microsystems (현재 Oracle) 에서 개발된 데이터베이스 접근 드라이버다.

사실상 자바 플랫폼의 핵심 API로 시작되어 현재까지 표준 데이터베이스 접근 방식으로 사용되고 있다.
## Spring JDBC란

`Spring` 개발팀이 `Spring Framework 1.0` 의 일부로 출시하며 같이 개발된 모듈로, `JDBC` 의 복잡성을 줄이고 생산성을 높이기 위해 만들어졌다.

따라서, `Spring JDBC` 라고 해서 특별한게 있는게 아닌, **기존 `JDBC` 의 래퍼**라고 생각하면 좋다.

### JdbcTemplate 

기존 `JDBC` 에서는 `PreparedStatement` 로 쿼리문을 준비하여 세팅하는 것과 달리, `Spring JDBC` 에서는 `JdbcTemplate` 이라는 클래스를 사용한다.

이때, `Spring JDBC` 가 왜 스프링 모듈인지 알 수 있는데, `JdbcTemplate` 는 `Spring Bean` 으로부터 받아와서 주입되기 때문이다.

따라서 `Repository` 코드를 만들때 아래처럼 만들 수 있다.

```java
@Repository  
public class CourseJdbcRepository {  
    private final JdbcTemplate jdbcTemplate;  
  
    private static String INSERT_QUERY =  
            """  
                INSERT INTO course
                values (?, ?, ?);  
            """;  
  
    public CourseJdbcRepository(JdbcTemplate jdbcTemplate) {  
        this.jdbcTemplate = jdbcTemplate;  
    }  
  
    public void insert(Course course) {  
        jdbcTemplate.update(INSERT_QUERY,  
                course.getId(),  
                course.getName(),  
                course.getAuthor()  
        );  
  
    }  
}

```

## 대표적인 차이점

`Connection` 을 얻어오는 코드가 추상화되어 개발자로 하여금 신경을 덜 쓰게 만들어준다.

리소스 해제, 예외 처리를 알아서 해준다.

또한, `ResultSet` 을 자동적으로 처리해주어 편리하다.

```java
// 전통적인 JDBC
Connection conn = null;
PreparedStatement pstmt = null;
try {
    conn = dataSource.getConnection();
    pstmt = conn.prepareStatement("INSERT INTO users (name, age) VALUES (?, ?)");
    pstmt.setString(1, "홍길동");
    pstmt.setInt(2, 20);
    pstmt.executeUpdate();
} finally {
    if (pstmt != null) pstmt.close();
    if (conn != null) conn.close();
}

// 스프링 JDBC
jdbcTemplate.update("INSERT INTO users (name, age) VALUES (?, ?)", "홍길동", 20);
```

## 무엇을 써야할까요?

현대 웹 애플리케이션 개발에서는 스프링 JDBC를 사용하는 것이 좋다.

다만, 더 높은 추상화를 제공하는 `JPA`나 `MyBatis` 같은 ORM/SQL 매퍼를 고려해볼 수도 있겠다.

어느 쪽이 정답은 아닌데, 그것은 비즈니스 로직이나 데이터베이스 사정에 따라 달라진다.

> 1. JDBC가 좋을 경우 (단순 쿼리가 좋을 경우)

- SQL을 직접 작성하고 싶을 경우
- **간단한 CRUD 작업일 경우** (즉, 억지로 JPA를 사용하는건 손해일 수도 있다.)
- 레거시 시스템과의 통합 (거의 적음)

> 2. JPA/MyBatis 가 좋을 경우

- 객체 지향적인 도메인 모델링이 될 경우
- 복잡한 `객체 관계`를 다룰 경우
- SQL 작성이 싫을 때
