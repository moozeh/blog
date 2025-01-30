---
title: "Spring Boot 시작하기"
date: 2025-01-26T00:50:17+09:00
tags: [Spring, SpringBoot]
categories: [Spring]
draft: true
---
<!-- truncate -->

## 주의점

기존 스프링 프레임워크 프로젝트와 달리 주의할 점이 있다.

### 의존성 설정하기 

기본적으로 `REST API` 어플리케이션을 만들 거면 상응하는 의존성을 설치해야한다.
## Spring Boot 의 목표

Spring Boot를 쓰면 **프로덕션 환경에서 사용 가능한** 애플리케이션을 **빠르게 빌드 할 수 있다.**

- `Beans`, `XML` 정의를 할 필요가 없다.

### 빠르게 시작하기 위한 여러 툴들

- [Spring Initializr](https://start.spring.io/) : Java 버전, Spring Boot 버전을 골라서 프로젝트를 빠르게 시작할 수 있다.
- Spring Boot Starter Projects : 프로젝트의 의존성들을 빠르게 정의할 수 있다.
- Spring Boot Auto Configuration : 클래스 경로에 있는 의존성에 따라 자동으로 설정이 적용된다.
- Spring Boot DevTools : 수동으로 서버를 다시 시작하지 않고도 애플리케이션을 변경할 수 있다.

### 프로덕션 환경에서 사용가능하게 만드는 기능들
- 로거 : Spring Boot 는 기본적으로 로깅을 제공한다.
- 여러 환경에 따른 다양한 설정
	- QA, DEV, 프로덕션 등
- 모니터링 기능 (Spring Boot Actuator)

## Spring Boot Start Projects

일반적으로 앱을 만들 때에는 많은 프레임워크가 필요하다.

당장 이부분만 보아도 그렇다.

```java
package org.moozeh.learn_spring.app12_springboot;  
  
import org.springframework.web.bind.annotation.RequestMapping;  
import org.springframework.web.bind.annotation.RestController;  
  
import java.util.Arrays;  
import java.util.List;  
  
// Rest Controller 가 그냥 Controller 와 다른 점은 무엇인가?  
  
@RestController  
public class CourseController {  
  
    // ~~ Mapping 메서드를 달아주면 알아서 요청에 대한 리턴 값을 해당 함수의 리턴값으로 매핑해준다.  
    @RequestMapping("/courses")  
    public List<Course> retrieveAllCourses() {  
        return Arrays.asList(  
                new Course(1, "Learn 1", "moozeh"),  
                new Course(2, "Learn 2", "moozeh")  
        );  
    }  
}
```

List를 JSON 변환하는 코드인데, 이를 `JSON` 형으로 다시 변환해서 보내주어야할 것이다.

그 외 것들을 나열하면, `REST API` 애플리케이션을 만드는데에는 이정도가 더 필요하다.

- WAS : `Tomcat` 
- `Spring MVC`
- `JUnit`, `Mockito` (테스트 코드까지 작성한다면..)

