---
title: "[Spring JPA] 테이블 상속에 관하여"
date: 2025-02-04 23:30:34 +0900
categories:
  - Backend
  - Spring
tags:
  - Spring
  - JPA
excerpt_separator: <!-- more -->
draft: false
image: /assets/img/template_spring-20250130224900580.webp
---


`Porring` 백엔드를 구현하면서, `OAuth` 혹은 네이티브 로그인 계정에 대한 ERD 타입을 [슈퍼타입과 서브타입](https://blog.moozeh.org/posts/erd-%EC%8A%88%ED%8D%BC%ED%83%80%EC%9E%85-%EC%84%9C%EB%B8%8C%ED%83%80%EC%9E%85%EC%97%90-%EB%8C%80%ED%95%B4%EC%84%9C-%EC%95%8C%EC%95%84%EB%B3%B4%EC%9E%90)으로 정의하였다. 

데이터베이스 상으로만 봤지만, 실제로 어떻게 구현을 해야할까? 단순 쿼리를 한다면 되겠지만, 복잡한 작업이 될 것이며, 쿼리 중간에 예상치 못한 버그가 있을 수 있다. `JPA` 에서는 어떻게 되는지 알아보자!

<!-- more -->

## @Inheritance 로 상속하기

다들 알겠지만, ERD 에서 슈퍼타입과 서브타입은 일종의 `상속 관계` 이다.

JPA에서의 상속은 `@Inheritance` 로 구현될 수 있다.

```java

// SINGLE_TABLE 전략
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
public abstract class Item {
    @Id @GeneratedValue
    private Long id;
    private String name;
}


// JOINED 전략 - @DiscriminatorColumn 선택사항
@Entity
@Inheritance(strategy = InheritanceType.JOINED)
public abstract class Vehicle {
    @Id @GeneratedValue
    private Long id;
}

@Entity
public class Car extends Vehicle {
    private String model;
}

// TABLE_PER_CLASS 전략 - 자바에서 상속 관계 유지
@Entity
@Inheritance(strategy = InheritanceType.TABLE_PER_CLASS)
public abstract class Payment {
    @Id @GeneratedValue
    private Long id;
}

@Entity
public class CardPayment extends Payment {
    private String cardNumber;
}
```

일반적인 `JoinedColumn` 등과의 차이점은, `PK` 값을 공유한다는 점이다.

상속을 통해 PK는 공유할 수 있으며, 코드의 중복을 줄일 수 있는 장점이 있다.

## 상속 전략

그렇다면, **실제 데이터베이스에서는 어떻게 구현이 될까?**

그것은 `@Inheritance` 의 상속 전략에 따라 결정된다.

`@Inheritance` 어노테이션의 `strategy` 속성을 아래와 같이 세가지 방식으로 정할 수 있다.
### 1. JOINED

`JOINED` 속성은 **특정 자식 타입을 부모와 자식 테이블의 JOIN으로 받아오는 전략이다.**

따라서 데이터의 정합성은 해당 방식이 가장 만족시켜줄 수 있다고 볼 수 있다.

하지만, JOIN 으로 인한 예기치 못한 성능 저하를 고려해야할 것이다.

```java
// 부모 테이블
package com.kolown.porring.account;  
  
import com.kolown.porring.common.BaseTimeEntity;  
import jakarta.persistence.*;  
  
@Entity  
@Table(name = "accounts")  
@Inheritance(strategy = InheritanceType.JOINED)  
@DiscriminatorColumn(name = "sub_type")  
public class Account extends BaseTimeEntity {  
    @Id  
    @GeneratedValue(strategy = GenerationType.AUTO)  
    private Long accountId;  
}

// 자식 테이블(서브타입)
package com.kolown.porring.account;  
  
import jakarta.persistence.*;  
  
@Entity  
@Table(name = "email_accounts")  
public class EmailAccount extends Account {
    private String email;
    private String password;  
}
```

실제 테이블 생성은 아래와 같이 되고, 데이터 조회 시 두 테이블이 `JOIN` 된다.

```sql
CREATE TABLE accounts (
    account_id BIGINT PRIMARY KEY,
    sub_type VARCHAR(31),
    created_at TIMESTAMP, -- BASETIME ENTITY 로 인한 생성
    updated_at TIMESTAMP
);

CREATE TABLE email_accounts (
    account_id BIGINT PRIMARY KEY,
    email VARCHAR(255),
    password VARCHAR(255),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
```


### 2. TABLE_PER_CLASS

이 방식은 애초부터 **부모타입의 테이블은 없으며, 서브타입별로 테이블을 분리하여 보관하는 전략이다.**

그렇기 때문에 앞서 이야기한 방식과는 달리 정합성을 지키지 않는다.

하지만, 상속 관계를 유지하는 것은 JPA 에게 있기 때문에 실제로 사용할 때에는 JOINED 방식처럼 사용해도 큰 차이가 없다.

```java
@Entity
@Inheritance(strategy = InheritanceType.TABLE_PER_CLASS)
public abstract class Vehicle {
    @Id @GeneratedValue
    private Long id;
    private String name;
}

@Entity
public class Car extends Vehicle {
    private String model;
}

@Entity
public class Airplane extends Vehicle {
    private String flightNumber;
}
```

```sql
-- 애초부터 별도의 테이블로 형성된 모습. 하지만

CREATE TABLE car (
    id BIGINT PRIMARY KEY,
    name VARCHAR(255),  -- 부모의 컬럼
    model VARCHAR(255)  -- Car의 컬럼
);

CREATE TABLE airplane (
    id BIGINT PRIMARY KEY,
    name VARCHAR(255),  -- 부모의 컬럼
    flight_number VARCHAR(255)  -- Airplane의 컬럼
);
```

### 3. SINGLE_TABLE

하나의 테이블에 모든 정보를 다 넣는 전략이다.

조인이 필요 없어서 조회 성능이 빠르나, **자식 엔티티의 컬럼은 모두 null 을 허용해야한다.**

실제로, 코드만 보면 별 차이가 없음을 느낄 것이다.

```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "vehicle_type")
public abstract class Vehicle {
    @Id @GeneratedValue
    private Long id;
    private String name;
}

@Entity
@DiscriminatorValue("CAR")
public class Car extends Vehicle {
    private String model;
}

@Entity
@DiscriminatorValue("AIRPLANE")
public class Airplane extends Vehicle {
    private String flightNumber;
}
```

하지만 실제로는 아래와 같이 정의가 된다. 완전 딴판이다.

```
CREATE TABLE vehicle (
    id BIGINT PRIMARY KEY,
    dtype VARCHAR(31),
    model VARCHAR(255),  -- Car의 컬럼
    flight_number VARCHAR(255),  -- Airplane의 컬럼
);
```
## @DiscriminatorColumn

Discriminator 란 한국어로 판별자를 뜻한다. 진위를 가리는 무언가를 뜻한다.

즉,  그렇다면 이렇게 해석할 수 있겠다.

>  진위를 가리는 컬럼

다시 말해 현재 찾아보는 엔티티가 정확히 **어떤 타입인지 판별하는 컬럼을 정의하겠다는 의미이다.**

### @DiscriminiatorValue

명시적으로 구분자 컬럼을 정의해준다. 부모 테이블의 컬럼 이름이 다르게 매핑하고 싶을 경우 사용하면 된다.

자세한 예시는 위 `SINGLE_TABLE` 예시를 살펴보자.

## @DiscriminatorColumn 은 필수인가?

오늘 코드리뷰를 하다가 위 제목과 같은 얘기가 오갔다.

결론적으로 꼭 그렇지 않지만, @DiscriminatorColumn 을 사용해서 얻을 수 있는 이점은 아래와 같다.

### SINGLE TABLE 사용 시에는 필수

반정규화를 어쩔 수 없이 해야하는 경우, 하나의 테이블 내에서 구분자를 기준으로 JPA가 값을 받아와야하기 때문에, **반정규화를 할 때에는 필수로 지목해주어야한다.**

그 외에는 필수가 아니지만, 구별자를 위해선 명시해두면 좋다.
### 명시적으로 어떤 컬럼값으로 연결되는지 확인할 수 있다.

그 다음은 코드의 가독성이 있을 수 있다.

사실 어떤 테이블이건 간에 관계 에 대한 문제는 관계 유형에 따라 달라진다.

상속이라는 문제도 `1:1` 관계 매핑에 해당되는 문제이기 때문이다.

그렇기에 실제로 판별자를 매번 매핑할 필욘 없겠지만, 우리가 코드를 읽을 때, **아, 이 컬럼을 바탕으로 두 테이블 사이에는 상속 관계가 있구나!** 정도는 확인하고 넘어갈 수 있다.

### 구분자 컬럼을 정의할 필요가 없다.

구분자 컬럼을 정의할 필요가 없어서 데이터의 무결성을 지키는 데에 도움이 된다.

이게 무슨 뜻이냐? 만약에 `order_id` 라는 구분자로 처리되고, 우리는 이를 `JPA` 에게 상속을 통해 맡기고 싶은 상황이 된다고 해보자.

이때, 우리는 `@DiscriminatorColumn` 으로 구분자 컬럼을 정의해주면, 실제 Entity 필드로 해당 컬럼을 정의할 필요가 없어지게 된다. **컬럼의 이름을 넘겨줌으로써 JPA에게 책임이 넘어가기 때문이다.**

그렇기에 해당 필드변수가 Spring Boot 코드 내에서 조작될 일이 없어지므로 해당 연결에 대한 데이터 무결성은 보장된다.

### 결론

테이블 JOIN을 하는 경우와 테이블별로 그냥 따로 만들 때에는 DiscriminatorColumn은 필수가 아니며,

Inheritance를 통해 서로 다른 테이블(TABLE_PER_CLASS)인 경우에도 하위타입인 것처럼 자바 코드에서 사용할 수 있다!

