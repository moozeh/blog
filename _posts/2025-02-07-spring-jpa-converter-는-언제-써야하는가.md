---
title: "[Spring JPA] Converter 는 언제 써야하는가"
date: 2025-02-07 00:23:30 +0900
categories:
  - Backend
  - Spring
tags:
  - Spring
  - JPA
excerpt_separator: <!-- more -->
draft: false
---

`Type` 을 정의하는 테이블을 정의해서 매핑하는데, Entity 와 ManyToOne을 쓰면 적절하지 않을 것 같았다.

ENUM 을 쓰면 적절하지 않을 것 같다는 의견을 검색하다가 보았고, 테이블을 정의해서 ENUM 처럼 쓰는게 좋아보일 것이라 판단했는데, `Claude` 로부터 `@Converter` 를 써보라는 추천을 받아서 알게 되었고 학습하게 되었다.

<!-- more -->
## @Converter 란

`@Converter` 어노테이션은 일종의 컴포넌트형 어노테이션의 일종이다.

즉, 하나의 클래스에 `@Converter` 어노테이션에 붙여야하고, 구현해야하는 여러가지의  컨버터 `interface` 르 가져 각각의 `Converter`는 여러가지의 종류의 Converter와 느슨하게 결합되어있다.

- AttributeConverter - 가장 일반적, 커스텀 변환 로직
- BaseConverter - 기본 타입 변환용
- ElementConverter - 컬렉션 요소 변환
- EnumConverter - enum ↔ DB 값 변환

### 일반적인 @Converter 구현

가장 일반적인 `AttributeConverter` 에 대해 알아보자.

앞서 언급된 `Type` 테이블로부터 특정 타입인지 하나의 엔티티에서 바로 조회를 해서 확인하고 싶은 경우가 있다.

`@Enumerated` 를 사용할 수도 있겠지만, 데이터베이스 구현 상 별도의 타입을 정의한 테이블에서 관리할 경우, 위와 같이 `@Converter` 를 사용해서 자연스럽게 매핑할 수도 있다.

```java
@Entity
@Table(name = "reaction_type")
public class ReactionType {
    @Id
    @Column(name = "react_code")
    private String code;
}

@Entity
@Table(name = "reactions")
public class Reaction {
    @Id
    private Long id;
    
    @Column(name = "board_id")
    private Long boardId;
    
    @Column(name = "account_id")
    private Long accountId;
    
    @Convert(converter = ReactionTypeConverter.class)
    @Column(name = "react_code")
    private ReactionType type;
    
    @Column(name = "deleted")
    private boolean deleted;
}

@Converter
public class ReactionTypeConverter implements AttributeConverter<ReactionType, String> {
    @Autowired
    private ReactionTypeRepository typeRepository;
    
    @Override
    public String convertToDatabaseColumn(ReactionType type) {
        return type.getCode();
    }
    
    @Override
    public TypeEntity convertToEntityAttribute(String code) {
        return typeRepository.findById(code).orElseThrow();
    }
}

```

### 코드 설명

`convertToDatabaseColumn` 은 database에 저장할때,  `convertToEntityAttribute` 는 JPA 엔티티로부터 getter 등으로 불러올때 호출되어 리턴되는 값이 반영된다.

- convertToDatabaseColumn: 엔티티 → DB 저장 시 호출
- convertToEntityAttribute: DB → 엔티티 조회 시 호출 (getter 포함)

### @Converter 의 특징

보통은 일반적인 커스텀 변환 **로직**이 추가 되기 때문에 엔티티로부터 불러올때 특별한 처리가 필요한 경우에 사용하면 유용하며다.

하지만, 그런 변환 로직들은 대개 `Entity` 의 책임 내에서 처리하게 되므로 하나의 Entity의 영역에서 벗어나 공통적인 변환을 위한 변환 계층이 필요할때 사용하게 된다.

- 여러 엔티티에서 재사용 가능
- 특정 타입/값의 일관된 변환 로직 제공
- DB 컬럼과 Java 객체 간의 공통 변환 규칙 정의

즉 위와 같은 상황에서만 유용하며, 그 외의 경우에는 다른 방식을 써보는 것을 추천한다.

## 왜 써야할까?

그래서 꼭 써야하는 이유에 대한 궁금증이 많았다. 

### 다른 대안들의 단점

쓸 수 있는 이유로 아래와 같은 대안의 단점이 있었다.

> ManyToOne 의 단점

- 항상 JOIN이 발생
- N+1 문제 가능성
- 영속성 컨텍스트 관리 필요

> Converter 의 장점

- JOIN 없이 직접 값 매핑
- 단순 코드 참조 시 더 효율적
- 영속성 컨텍스트 부담 감소

하지만 실제로는 단순한 `Type Table` 의 경우 `ManyToOne`이 더 효율적이고 간단하다.

그래서 실제로 **일반적인 대부분의 상황에서는 ManyToOne을 사용한다.**

### @Converter 를 사용할 때 : 테이블 캐싱

하지만 `ManyToOne` 은 매번 조회시 `JOIN` 이 일어나게 되므로 성능저하가 일어난다.

따라서, 이런 경우 캐싱을 적용한다. ~~캐싱은 신이야..~~

즉, 타입 테이블을 미리 메모리에 올려서 메모리 내에서 JOIN을 시키는 것이다...!

어차피 타입 테이블의 경우 크게 추가되지 않는 경우가 대부분이기 때문에 변화될 일이 적기 때문에 메모리에 올려도 괜찮다고 판단될 경우 올려버릴 수 있는 것이다..!

```java

@Service
public class ReactionTypeCache {
    private Map<String, ReactionType> cache;
    
    @PostConstruct
    public void init() {
        cache = reactionTypeRepository.findAll()
            .stream()
            .collect(toMap(ReactionType::getCode, type -> type));
    }
    
    public ReactionType getType(String code) {
        return cache.get(code);
    }
}
```

이렇게 별도의 캐시를 두고, 이 `Cache` 를 Converter 에서 넣어서 사용해볼 수도 있을 것이다!

그렇게 되면 `DB 조회` 횟수도 감소되고, 그에 따라 응답시간도 개선될 수 있을 것이다.

### 2nd Level cache

이런 종류를 `Second Level Cache` 라고 부르며, 대개 **애플리케이션 수준에서 일어나는 캐싱**을 뜻한다.

왜냐하면 이러한 캐시는 `하나의 트랜잭션 범위`가 아니기 때문에 영속성 컨텍스트 단위가 아니며, 여러 트랜잭션을 아우르는 정보를 캐싱하기 때문이다.

결론적으로 캐싱이 필요한 정말로 극한의 상황이 아니라면 자주 쓰진 않을 것 같다...