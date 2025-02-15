---
title: "[Spring JPA] @Embeddable 을 이용한 복합 PK 키 설정하기"
date: 2025-02-16
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


[Porring 프로젝트를 진행하면서 엔티티 설정을 마치고,](https://github.com/Kolown-kr/porring-server/pull/9) 복합키에 관한 지적을 받았다.

AI를 이용해서 만든 코드인데, 미처 검증하지 못한 부분에 대해서 다시 생각해보게 되었고, 복합 PK 키를 JPA 에서 어떻게 설정하는지 한번 알아보려고 한다.

<!-- more -->

## 먼저, 복합 키란?

복합키는 말 그대로 여러 개의 컬럼들을 하나로 묶어서 키로 정의한 것을 복합키라고 한다.

기본적으로 복합 인덱스 라고 하면, 여러 컬럼에 대한 인덱스를 뜻할 것이고, 복합 키라고 하면, 외래 키 혹은 기본 키(PK) 에 대해서 복합적인 컬럼이 그 기준이 되는 것을 뜻한다.
## Spring 에서 복합 PK를 설정하는 방법

일단 두가지 방식으로 접근할 수 있다.

1. `@IdClass` 사용하기
2. `@EmbeddedId` 사용하기

주의할 점으로는 두 어노테이션 모두 JPA 1.0(JSR-220)부터 존재했다고 하며, 어느 쪽이 더 좋은 쪽은 아니다! 따라서 저마다의 방식이 있기 때문에 장단점을 살펴볼 필요가 있다.

그럼 각각에 대한 차이를 알아보자.

### `@IdClass`

백문이불여일견, 해당 예시 코드부터 보자.

```java
// ID 클래스 정의
public class OrderItemId implements Serializable {
    private Long orderId;
    private Long itemId;
    
    // 기본 생성자, equals(), hashCode() 구현 필요
}

// 엔티티 클래스
@Entity
@IdClass(OrderItemId.class)
public class OrderItem {
    @Id
    private Long orderId;
    
    @Id
    private Long itemId;
    
    // 다른 필드들...
}
```


기본적으로 `ID` 에 해당되는 클래스를 정의하고, `@IdClass`, 즉 **이 키의 기본키는 이렇게 될 것이다.** 라고 정의해주는 것이다.

 `@IdClass` 의 가장 큰 특징은 **엔티티 구현 내부에서 데이터베이스 기본키 필드를 한눈에 확인할 수 있다는 점이다.**

사실상 우리가 `ERD` 로부터 그대로 구현해야하는 상황일 경우 이런 방식이 도움이 될 것이다.

하지만 단점으로는, `Id` 클래스를 만들어정해주어야하는 점, 그로 인해 필드 정의가 중복된다는 점이 있다. 다시말해, 내부구현을 바꾸게되면 동일하게 바꿔줘야한다.

#### 필드 접근 (조작)

하지만 아래 코드처럼, 직접 필드 접근이 가능하여 **데이터베이스에 가까운 조작이 필요할 경우 해당 방식이 유리할지 모른다.**

```java
OrderItem orderItem = new OrderItem();
orderItem.setOrderId(1L);  // 직접 필드 접근
orderItem.setItemId(2L);   // 직접 필드 접근
```

#### 조회

일반적인 `entityManager`를 통한 조회는 아래와 같이 할 수 있다.

`@IdClass` 를 통해 `Id` 값이 클래스를 통해 매핑되었기 때문에, 조회역시 동일한 `IdClass` 로 해주어야한다.

```java
// 조회 시
OrderItemId id = new OrderItemId(1L, 2L);
OrderItem item = em.find(OrderItem.class, id);
```


하지만 나는 결국 직접 클래스에 필드를 두번 주입해야한다는 점, 직접 필드 접근을 통해 조작에 예상할 수 없는 부작용이 있는 점 등으로 인해 마음에 들지 않았고, 몇가지 방법을 찾은 끝에 `@EmbeddedId` 라는 어노테이션이 있음을 알게 됐다.

### `@EmbeddedId`

이번에도 일단 해당 예시부터 보자.

```java
// 복합키 클래스
@Embeddable
public class OrderItemId implements Serializable {
    private Long orderId;
    private Long itemId;
    
    // 기본 생성자, equals(), hashCode() 구현 필요
}

// 엔티티 클래스
@Entity
public class OrderItem {
    @EmbeddedId
    private OrderItemId id;
    
    // 다른 필드들...
}
```


해당 방식의 가장 큰 특징은 **복합 키를 하나의 엔티티로 다룬다는 점이다.**

또한 가장 큰 특징은 **내부 필드에 바로 `OriderItemId` 자체를 삽입한다는 것이다.** 그래서 Embeddable 인 것이고, 위 예시의 경우 이렇게 데이터베이스가 매핑된다.

```sql
CREATE TABLE order_item (
    order_id BIGINT NOT NULL,    -- OrderItemId의 orderId
    item_id BIGINT NOT NULL,     -- OrderItemId의 itemId
    quantity INTEGER,
    PRIMARY KEY (order_id, item_id)
);
```

하지만 실제 `JPA`로 접근 시에는 해당 키를 사용하는 클래스를 바로 가져와서 `Id` 필드를 지정해주면 되니, 좀 더 **자바 객체에 가까운 설계라고 할 수 있다.** 

캡슐화 또한 잘 되어 있어 원하는 구현을 직접 참고할 수 있다.

또한 실제 내부 쿼리도 하나의 테이블 내에서 같이 이루어지기 때문에 자바 객체로써 객체지향적인 설계를 하면서 동시에 `JPA` 에게 내부 테이블 접근 방식을 맡길 수 있다. 즉, 굳이 최적화할 필요가 없단 의미이다. (일반적인 의미에선.)

실제 DB 작업시에는 `Id`를 담당하는 객체를 분리하여 처리하기 때문이다.

```sql
INSERT INTO order_item (order_id, item_id, quantity) 
VALUES (1, 2, 10);
```

#### 필드 접근 (조작)

예를 들면 아래와 같이 각각의 복합키 필드에 따로따로 접근할 필요 없이, `IdClass` 를 새롭게 정의해야한다. 이로 인해 복합키 클래스는 불변성이 있으면 좋을 것이라 판단한다.

```java
OrderItemId id = new OrderItemId(1L, 2L);
OrderItem orderItem = new OrderItem();
orderItem.setId(id);  // 복합키 객체를 통해 접근
```

#### 조회

조회는 `@IdClass` 와 동일한 방식으로 접근한다.

## 주의 점

별도의 주의점이 있는데 아래와 같다.

1. 기본 생성자가 있어야 함
2. `equals()`와 `hashCode()` 메서드를 올바르게 구현해야 함
3. 변경 불가능한(immutable) 클래스로 만드는 것을 권장

왜 그렇게 해야할까?

기본 생성자야 당연히 새롭게 정의한다면 필요할 것이다. Generated 된 변수면 이에 대한 어노테이션을 정의해주면 된다. 

다만, `Serializable` 인터페이스를 구현해주어야하는데, 왜 직렬화가 가능하도록 만들어야할까?
### 식별자 클래스에 직렬화가 필요한 이유

이는 `JPA` 가 엔티티를 저장 및 조회 시 식별자를 직렬화해서 사용하기 때문이다.

이 뜻은, 당연히 복합 키에 해당되는 컬럼값들을 직렬화해서 DB에 저장한단 의미가 아니고 JPA 구현체(예: Hibernate)가 내부적으로 엔티티를 관리하는 과정에서 사용한다는 의미이다.

영속성 컨텍스트를 기준으로 보자.

> [!note] 간단히 알아보기 : 영속성 컨텍스트란?
> 
> 영속성 컨텍스트(Persistence Context)는 JPA가 엔티티를 관리하는 가상의 환경 또는 컨테이너를 뜻한다.
> 
> 알아서 성능 최적화가 되거나 (1차 캐시) 트랜잭션을 지원한다. 영속성 컨텍스트로 인해 데이터의 영속성이 보장된다.

JPA 는 내부적으로 **영속성 컨텍스트에서 내부 맵에서 키로 사용된다.**

그렇기 때문에 이것을 직렬화할 필요가 있는 것이다.

그렇지 않다면 객체로 저장해야하는데, 할당받은 객체의 식별번호값이 실제 데이터베이스 내 해당되는 복합키와 동일성이 보장되지 않기 때문이다.

그렇기 때문에 `Serializable` (직렬화 가능한 것) 을 상속받아야하는 것이고, 이는 곧 `성능문제` 로 이어질 수 있다.  분산 환경 / 캐시 사용에 문제가 될 수 있기 때문이다. 예를 들면 직렬화 불가능하다고 판단될 경우 `Mapping` 을 못하게 될 것이고 이는 곧 캐시를 쓰지 못하는 결과로 이어질 것이다.

### 식별자 클래스에 `equals`, `hashCode`가 필요한 이유
 
그렇다면 `equals`, `hashCode` 메서드를 구현해야하는 이유도 동일하게 이해될 것이다.

이들은 **영속성 컨텍스트에서 엔티티 간의 동일성 비교를 위해 요구되며, `Serializable` 과는 독립된 요구사항이다.**

결국 모두  **필수사항은 아니나, 성능에 영향이 생길지도 모르기 때문에 되도록이면 구현하도록 하자.**
