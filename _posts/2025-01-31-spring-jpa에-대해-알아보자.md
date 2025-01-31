---
title: "[Spring] JPA에 대해 알아보자"
date: 2025-01-31 22:39:35 +0900
categories:
  - Backend
  - Spring
tags:
  - Java
  - ORM
  - Database
  - Backend
  - JPA
draft: false
excerpt_separator: <!-- more -->
---

<!-- draft 값을 false 혹은 제거해야 게시됩니다!!! -->

 JPA 에 대해 기본적인 내용을 훑는다. 기본적인 내용을 알고 있다면 무시해도 좋다.

<!-- more --> 

## JPA 를 사용하는 이유

JPA를 사용하는 이유는 쿼리를 수행하는 테이블의 개수가 복잡해질수록 간단하게 코드 구현이 가능하기 때문이다.  

## Entity의 정의

JPA를 사용하면, Bean 데이터를 직접 테이블로 매핑할 수 있는데, 이때 이 Bean을 엔티티 라고 부르게 된다. 즉, `Entity` 는 `Bean` 이다. 

**추가적으로 더 나아가면 Nest.js 에서 엔티티를 어떻게 정의할지 생각해볼 수 있을 것이다.**  꼭 Database 코드에 있어야하는 이유가 없고, `Bean` 을 어떻게 활용할지 생각해보면 엔티티를 사용하는데 있어서 이해가 빠를 것이다.

기본적으로 나는 `Nest.js`부터 얕게 공부했기에 `Entity` 와 `DTO` 를 어떻게 써야할지 헷갈렸었다.

이때, Entity는 데이터베이스와 매핑이 되는 Bean 이기 때문에, `Primary Key` 가 존재해야할 것이다. 이는 `@Id` 어노테이션으로 명시해줄 수 있다.

각각의 컬럼과 속성을 연결해주는데 `@Column` 으로 명시적으로 연결해줄 수 있다. 자동 연결도 지원하니 편하다!

```java
package org.moozeh.learn_spring.app16_jpa;  
  
import jakarta.persistence.*;  
  
/**  
 * jakarta.persistence.Entity 도 있고, org.hibernate.annotations 도 있다.  
 * 이는 결국 구현체가 hibernate 이기 때문이다.  
 * *   
 */  
@Entity(name="courses")  
public class Course {  
    @Id  
    private long id;  
  
    @Column(name="name") // 같은 이름으로 매칭된다면 이 값(annotation 전체)은 사실 불필요하다.  
    private String name;  
    // @Column(name="author")  
    private String author;  
  
    public Course() {}  
  
    public Course(long id, String name, String author) {  
        this.id = id;  
        this.name = name;  
        this.author = author;  
    }  
  
    public long getId() {  
        return id;  
    }  
  
    public String getName() {  
        return name;  
    }  
  
    public String getAuthor() {  
        return author;  
    }  
  
    @Override  
    public String toString() {  
        return "Course{" +  
                "id=" + id +  
                ", name='" + name + '\'' +  
                ", author='" + author + '\'' +  
                '}';  
    }  
}
```

이렇게 하여, 테이블 - 엔티티 간 '매핑'을 이용해서 값을 삽입하고 조작할 수 있게 되는 것이다.
### JPA Repository 정의하기

다음으로 엔티티가 정의되면, 이를 이용해 repository 를 정의할 수 있다.

JPA에서는 Entity 와 레포지토리를 실제로 매핑시키려면, `EntityManager` 를 불러오면 된다. 
Entity 매니저는 말그대로 엔티티와 관련된 작업들이 수많이 정의되어있는 매니징 클래스이다. 

또한, 기본적으로  트랜잭션이 없으면 하면 에러가 생긴다. 

기본적으로 이를 해결하는 방법은 `@Transactional` 어노테이션을 정의하여 트랜잭션의 범위를 설정해주면 된다.

즉, 기본적으로 JPA 레포지토리 코드는 트랜잭션을 기반으로 작동해야 함을 의미한다.


```java
package org.moozeh.learn_spring.app16_jpa;  
  
import jakarta.persistence.EntityManager;  
import jakarta.persistence.PersistenceContext;  
import jakarta.transaction.Transactional;  
import org.springframework.beans.factory.annotation.Autowired;  
import org.springframework.stereotype.Repository;  
  
@Repository  
@Transactional  
public class CourseJpaRepository {  
    @PersistenceContext 
    private EntityManager entityManager;  
  
    /**  
     * Entity 라고 해서, 데이터베이스에서만 만들 필요는 없다.  
     *     * 기존 Bean으로 사용하듯이 그냥 사용하면 되는 것이다.  
     * @param course  
     */  
    public void insert(Course course) {  
        entityManager.merge(course); // 이렇게 하면, 엔티티 내 Bean과 매핑된 데이터베이스에 알아서 저장할 것이다! 정말 편하다.  
    }  
  
    public Course findById(long id) {  
        return entityManager.find(Course.class, id); // 두번째 인자로 PK가 들어간다.  
        // 그렇다면, PK가 아닌 다른 인덱싱된 레코드로 검색하려면..?  
    }  
  
    public void deleteById(long id) {  
        Course course = entityManager.find(Course.class, id);  
        entityManager.remove(course);  
    }  
}
```

### setter 가 사라졌다.

하나 중요한 점은 `setter` 가 필요하지 않게 되었다는 점이다.  

이 뜻은 다시 말해 Bean이 초기화될 때, 값 Setting을 미리 전부 마칠 수 있게 된 것을 의미한다.

JDBC로 직접할 때에는 setter 가 있어야 jdbcTemplate에서 정보를 받아올 수 있었다.

JPA를 사용함으로써 Entity 생성 시점이 JPA 내에서 캡슐화되었다고 볼 수 있겠다.  이것이 `Spring Data JPA`의 특징이다.

### 영속성 컨텍스트

단순히 Autowiring 하는 것보다 더 좋은 방식이 있는데,  이것이 Jpa의 바로 그 `영속성 컨텍스트` 이다. 

이에 관해서는 상세하게 다시 알아볼 예정이다.

## 디버깅 수행하기

`application.properties` 값으로 아래와 같은 값을 추가하면, 생성된 SQL을 확인할 수 있다.  

```
spring.jpa.show-sql=true
```

그렇다면, `CommandLineRunner` 를 이용해서 **스프링이 시작되자마자 특정 함수를 실행시켜서 확인해보자.**

```java
package org.moozeh.learn_spring.app16_jpa;  
  
import org.springframework.boot.CommandLineRunner;  
import org.springframework.stereotype.Component;  
  
@Component  
public class CourseJpaCommandLineRunner implements CommandLineRunner {  
    private final CourseJpaRepository courseJpaRepository;  
  
    public CourseJpaCommandLineRunner(CourseJpaRepository courseJpaRepository) {  
        this.courseJpaRepository = courseJpaRepository;  
    }  
  
    @Override  
    public void run(String... args) throws Exception {  
        this.courseJpaRepository.insert(new Course(1, "Learn AWS", "moozeh"));  
        this.courseJpaRepository.insert(new Course(2, "Learn DevOps", "moozeh"));  
        this.courseJpaRepository.insert(new Course(3, "Learn Spring", "moozeh"));  
        this.courseJpaRepository.deleteById(1);  
        System.out.println(this.courseJpaRepository.findById(2));  
    }  
}
```

이렇게, `insert` 문 3개와 `delete` 문 1개, 그리고 `select` 문 1개를 실행시켜봤다. 아래처럼 실행되고 있다.

이때, `show-sql` 값이 `true` 라면, 각각의 실제로 실행되는 쿼리문을 보여준다.

```
Hibernate: select c1_0.id,c1_0.author,c1_0.name from courses c1_0 where c1_0.id=?
Hibernate: insert into courses (author,name,id) values (?,?,?)
Hibernate: select c1_0.id,c1_0.author,c1_0.name from courses c1_0 where c1_0.id=?
Hibernate: insert into courses (author,name,id) values (?,?,?)
Hibernate: select c1_0.id,c1_0.author,c1_0.name from courses c1_0 where c1_0.id=?
Hibernate: insert into courses (author,name,id) values (?,?,?)
Hibernate: select c1_0.id,c1_0.author,c1_0.name from courses c1_0 where c1_0.id=?
Hibernate: delete from courses where id=?
Hibernate: select c1_0.id,c1_0.author,c1_0.name from courses c1_0 where c1_0.id=?
```


또한, 분명 스키마에서는 `course` 라는 테이블을 정의했는데, `c1_0.id` 와 같은 테이블에서 찾고 있다.

이는 테이블의 별칭(alias) 으로, `Hibernate` 에서 자체적으로 테이블 명을 관리하고 있음을 알 수 있다.

