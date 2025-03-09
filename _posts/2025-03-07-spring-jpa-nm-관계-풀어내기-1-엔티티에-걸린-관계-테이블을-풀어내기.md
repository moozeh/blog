---
title: "[Spring JPA] 영속성 컨텍스트 시리즈 (2) - N:M 관계 엔티티로 풀어내기"
date: 2025-03-07 17:00:36 +0900
categories:
  - Backend
  - Spring
tags:
  - Spring
  - JPA
  - PersistenceContext
excerpt_separator: <!-- more -->
draft: false
image: /assets/img/2025-03-07-spring-jpa-nm-관계-풀어내기-1-엔티티에-걸린-관계-테이블을-풀어내기-20250307170115389.webp
---
`Porring` 프로젝트를 하면서 다대다 관계를 만들 때 관계에 대한 엔티티를 만들지 말지를 고민했는데, 결국엔 만들었다.

왜냐하면, 관계 자체를 검색할 일이 많았으니까 관계가 주를 이룬다고 생각했기 때문에 그렇게 생각했다.

하지만 다대다 관계에서는 만들 수도 있고, 만들지 않을 수도 있다. `@ManyToMany`  어노테이션을 사용하면 만들 수 있다고 들었다.

하지만, 실무에서는 왠만해선 사용하지 말라는 의견이 많은데 그 이유를 알아보자.

<!-- more -->

물론! 이 부분은 `JPA` 에 준하는 이야기다. 왜냐하면 `JPA` 의 엔티티의 영속성 컨텍스트를 살펴봐야하기 때문이다.

경우에 따라 관계 자체를 엔티티로 설정해야할 수도 있겠지만 (추가 정보가 있거나) 대부분의 경우 `CascadeType` 옵션으로 유연하게 풀어나갈 수 있다.

오늘은 `ERD` 및 관계형 데이터베이스의 관계에 대해 이야기할 것이므로 데이터베이스 설계와도 밀접한 연관이 있다.

## JPA 의 Cascade 관계 

일단, 관계 테이블을 정의하는 것 자체에 대해서 고찰을 해볼 예정이다.

JPA 에서는 관계 테이블을 어떻게 가져올까를 먼저 생각해봐야한다. 

당연히, `@OneToMany`,  `@ManyToMany` 등의 어노테이션과 이와 연계된 엔티티를 정의하여 풀어낼 수 있을 것이다.

결론부터 말하자면 **일반적인 경우 왠만해선 추가적인 정보가 없다면, 굳이 풀어낼 필요가 없다.**  *추후에 실무적인 관점에서 다시 접근하기 때문에 일차적으로는 이렇게 적었다.*

왜냐하면 `Cascade`  옵션을 조절하여 특정 테이블 내의 엔티티 정보만 가져올 수 있다. 이 정보는 `JPA` 스펙에 정의되어 있다.

[이곳](https://jakarta.ee/specifications/persistence/2.2/apidocs/javax/persistence/cascadetype)에 잠깐 들어가보자. 얼마 안걸린다. 이곳에서 `JPA` 에 정의되어있는 `CascadeType` 들을 살펴볼 수 있으며, 이를 통해서 우리는 불필요한 엔티티를 만들 필요가 없게 할 수 있다.

![[2025-03-07-spring-jpa-nm-관계-풀어내기-1-엔티티에-걸린-관계-테이블을-풀어내기-20250308105324635.webp]]
_CascadeType_

### 잠깐, Cascade 란?

아까부터 `Cascade` 라는 용어를 사용하고 있었는데, Cascade 란 뭘까?

일단 영어 단어의 정의부터 살펴보자.

> Cascade : 종속, 작은 폭포

![[2025-03-07-spring-jpa-nm-관계-풀어내기-1-엔티티에-걸린-관계-테이블을-풀어내기-20250308105649458.webp|242]]
_종속과 작은 폭포가 무슨 관련이 있을까_

우리가 흔히 `CSS` 문서(정확히는 스타일 시트 언어) 에서 정의되는 `Cascading` 의 의미와 동일하다. 즉, 폭포처럼 위에서부터 내려가는 구조를 뜻하는 의미라고 한다.

`Cascade` 옵션을 사용하면 폭포처럼 **특정 엔티티와 연관된 엔티티들의 작업이 어디까지 영향이 미치게 할지 정할 수 있다.** 다시 말해서, 백엔드에서는 **엔티티 간 연관관계로 이어진 관계에서 전파되는 개념을 뜻한다.**

이 옵션들은 같이 정의되어있는 **영속성 컨텍스트**와 밀접한 관련이 있으며, 실제로 아래 해당되는 `CascadeType` 은 엔티티의 생명주기 단계와 유사하게 대응된다. (완전한 대응 X)
### CascadeType

해당 작업을 할 때 전파가 됨을 의미한다.

쉽게 풀어 말하자면, 특정 엔티티 (부모) 에서 한 작업이 연관된 엔티티 (자식) 으로 전파되는 기준을 정의한다.

엔티티가 [영속성 컨텍스트에서 관리되는 만큼](https://blog.moozeh.org/posts/spring-jpa-%EC%97%94%ED%8B%B0%ED%8B%B0%EB%8A%94-%EC%96%B4%EB%96%BB%EA%B2%8C-%EC%A0%80%EC%9E%A5%EB%90%A0%EA%B9%8C-1), 생명주기와도 관련 있는 것이다.

- All : 모든 작업이 전파
- Detach : 분리 작업'만' 전파
- Merge : 병합 작업'만' 전파
- Persist : 저장 작업'만' 전파
- Refresh : 새로고침 작업'만' 전파
- Remove : 삭제 작업'만' 전파

완전히 대응되지는 않는 이유로 `FetchType` 이 있다. 이를 이용하여 엔티티 조회 시에 전파를 할 수 있다. 엔티티의 로딩 작업은 이를 이용해야할 것이다.

## 다대다 관계 풀어내기 0 - 정의 다시 짚어가기

일단은 다대다 관계를 해결하기 전에, 한가지 명확하게 짚고 넘어가야한다.

이 부분은 원래 포함하지 않으려고 했지만, 글을 쓰다보니 헷갈려서 쓰게 됐다. 

> 1:N, N:1, N:M 의 기준은 정확히 어떻게 되는 걸까?

이 질문에 대해서 다시 생각을 해보고 기록을 하려고 한다.

일대다, 다대일의 관계는 간단하다. 일에 해당하는 엔티티 객체가 하나면, 이 하나의 객체 (레코드)와 **관계된** 다에 해당 되는 엔티티는 여러개 일 것이다. 라는 게 일반적인 생각이다.

하지만, 관계 엔티티 자체가 정의되면 이런 생각이 헷갈리기 쉬울 수 있다.

```java
@Entity
public class BoardTag {
    @Id
    @GeneratedValue
    private Long id;
    // 또는 복합 키 사용
    
    @ManyToOne
    @JoinColumn(name = "board_id")
    private Board board;
    
    @ManyToOne
    @JoinColumn(name = "tag_id")
    private Tag tag;
    
    // 추가 필드들...
}
```

위 엔티티 코드를 보자.  위 엔티티는 `Board` 와 `Tag` 를 이어주는 관계 엔티티이다.

하나의 게시물이 여러개의 태그를 달 수 있고, 여러 게시물에서 동일한 태그를 달 수 있다 (다대다 관계) 라고 해보자.

그렇다면, BoardTag 엔티티에서 왜 ManyToOne 일까 에 대해서 한번 생각해봤을 때 헷갈리는가? 헷갈리지 않는다면 당신만의 정확한 기준이 있을 것이고, 헷갈린다면 나와 같은 상황이라고 볼 수 있을 것이다.

> 관계 자체를 의미하는 엔티티는 하나다.
> 
> 이 관계 엔티티 하나는  각각 하나의 `Board` 와 `Tag` 를 참조 하니까, 저기서는 `OneToOne`이라고 적어야하는게 아닐까?

이 관계가 왜 다대일 인지 생각해보았을 때, **관계의 정의에 대해서 생각해봐야한다.**

### 데이터베이스 관계는 IP와 같은 연결 정보이다.

1:N 관계라고 할 때, 관계의 1 과 N 을 따로 떼서 각각의 엔티티에 대입해서 봐야하는게 아니고, 관계 자체가 두 엔티티 간의 연결 정보라고 생각해야한다. 마치 네트워크에서 `IP` 의 개념이라고 봐야하듯이 말이다.

**`IP` 는 컴퓨터의 정보가 아니라, 두 노드 간의 연결 정보를 담는다.**

이와 같이,  `BoardTag` 의 입장이 아니라, `Board` 와 `Tag` 에서 어떻게 이어질지를 생각해봐야한다는 의미이다.

즉, Board 에서는 `BoardTag` 를 여러개 가질 수 있으므로, `BoardTag` 에서의 `Board` 프로퍼티는 `@ManyToOne` 이 되는 것이다.

동일하게, `@OneToOne` 은 양 쪽 모두에서 하나만 가질 수 있을 때 사용해야한다.
## 다대다 관계 풀어내기 1 - @ManyToMany 의 존재 의의

그렇다면 우리는 다대다 관계에서 테이블을 굳이 쓰지 않는 이유는 무엇일까?

관계 테이블을 따로 설정하지 않는 이유로 영속성 컨텍스트의 캐시기능에 의의가 있다.

예를 들어 게시판에 태그를 다는 기능이 필요하다고 하자.

이때, 게시판 엔티티 Board 혹은 태그 엔티티 Tag에서 상대방을 관계로 가져올때, OneToMany 어노테이션으로, 그리고 그 속성 중 Casecade를 이용하면 상대 엔티티 작업을  언제 할지를 고를 수 있다.

또한, 이때 `@JoinTable` 을 이용하면 실제 물리적인 관계는 유지하면서, 다대다 관계를 엔티티만으로 유지할 수 있게 된다. 즉, **다대다 관계를 우리가 다루고자하는 객체만으로 풀어낼 수 있다. (관계를 위한 객체에 대한 관심을 없앨 수 있다.)**

```java
@Entity
public class Board {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
	
	// joinTable을 통해 데이터베이스의 물리적 구현에 대한 관심분리가 이루어진다.
    @ManyToMany(cascade = CascadeType.ALL)
    @JoinTable(
        name = "board_tag",
        joinColumns = @JoinColumn(name = "board_id"), 
        inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    private Set<Tag> tags = new HashSet<>();
    
    // getter, setter 등
}
```

그래서 `추가적인 정보가 없다면` 엔티티를 만들 필요가 없는 것이다. 실제 데이터베이스의 구현을 신경쓰지 않도록 하는 `ORM` 의 목적에 부합하는 아주 좋은 예시인 것이다!

지금까지의 정보대로라면, 새로 생성하는 것과 불러오는 것 (CRUD 의 CR) 정도는 간단히 할 수 있을 것이다. 그야 `Cascade` 속성과 `@JoinTable`을 이용하여 관계 테이블과 상대 엔티티까지 생성 정보를 전파시키면 되기 때문이다.

**다대다에서 엔티티를 굳이 만들 필요가 없는 상황에서, 이 관계를 갱신 (Update / Delete) 하기 위한 좋은 방법은 무엇일까?** 나는 이것이 되지 않아서 직접 관계 엔티티를 만들어서 직접 삭제를 해주려고 했었다.

업데이트 또한, 기본적인 방법은 쉽다. JPA 에서 갱신을 하기 위해서는 단순히 `Set.clear()` 과 `Set.addAll()` 메서드를 활용하면 된다.

앞서 언급된 예시의 코드를 살펴보자. 아래 코드는 `Set` 컬렉션으로 관계를 표현하여 데이터베이스 관계를 자바 객체로써 사용할 수 있도록 해준다.

```java
@Entity
public class Board {
    @Id
    @GeneratedValue
    private Long id;
    
    @ManyToMany(cascade = CascadeType.ALL)
    @JoinTable(
        name = "board_tag",
        joinColumns = @JoinColumn(name = "board_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    private Set<Tag> tags = new HashSet<>();
}

@Transactional
public void updateBoardTags(Long boardId, Set<Tag> newTags) {
    Board board = boardRepository.findById(boardId).orElseThrow();
    
    // 1. board_tag 테이블에서 해당 board_id를 가진 모든 레코드 삭제
    board.getTags().clear();
    
    // 2. 새로운 태그 컬렉션의 각 태그마다 board_tag 테이블에 레코드 추가
    board.getTags().addAll(newTags);
}
```


## 다대다 관계 풀어내기 2 - 실무적인 접근

자, 이제 본론으로 돌아와보자. **과연 이게 실제로 필요한 내용일지 생각해보자는 것이다.**  원래 나는 그냥 간단한 경우 이렇게만 구현해도 된다고 생각했지만, 요구사항이 바뀔 수도 있는 실무 환경에서는 다르게 접근해야한다는 입장이 대다수였다.

우리는 **확장성**에 염두에 두고 백엔드 코드를 작성해야 유지보수하기가 쉽다. 위 방식이 유지보수의 관점에서는 좋은 방식일까를 생각해보면 처음에 작성하는 것이 귀찮긴 해도 후처리의 입장에선 이 방식이 관리하기 편하다.

### 추가적인 정보를 추가할 때 귀찮아짐(유지보수 어려움)

당장 위의 `Tag` 의 예시만 보아도, 태그가 추가된 날짜, 연관된 태그 목록 등과 같은 추가적인 필드를 추가하려면 결국엔 관계 엔티티를 추가해야한다는 입장이다.

```java
package com.kolown.porring.account.entity;  
  
import jakarta.persistence.Column;  
import jakarta.persistence.Entity;  
import jakarta.persistence.FetchType;  
import jakarta.persistence.GeneratedValue;  
import jakarta.persistence.GenerationType;  
import jakarta.persistence.Id;  
import jakarta.persistence.JoinColumn;  
import jakarta.persistence.ManyToOne;  
import jakarta.persistence.Table;  
import lombok.AccessLevel;  
import lombok.Getter;  
import lombok.NoArgsConstructor;  
import org.hibernate.annotations.SoftDelete;  
import org.hibernate.annotations.SoftDeleteType;  
  
@Entity  
@Table(name = "accounts_follow")  
@NoArgsConstructor(access = AccessLevel.PROTECTED)  
@SoftDelete(columnName = "deleted", strategy = SoftDeleteType.DELETED)  
@Getter  
public class AccountFollow {  
    @Id  
    @GeneratedValue(strategy = GenerationType.IDENTITY)  
    @Column(name = "account_follow_id", nullable = false)  
    private Long id;  
  
    @ManyToOne(fetch = FetchType.LAZY)  
    @JoinColumn(name = "follower_id", referencedColumnName = "account_id", nullable = false)  
    private Account follower;  
  
    @ManyToOne(fetch = FetchType.LAZY)  
    @JoinColumn(name = "followee_id", referencedColumnName = "account_id", nullable = false)  
    private Account followee;  
  
  
    @Column(name = "nickname", columnDefinition = "VARCHAR(255)")  
    private String nickname;  
  
    public AccountFollow(Account follower, Account followee, String nickname) {  
        this.follower = follower;  
        this.followee = followee;  
        this.nickname = nickname;  
    }  
  
    public void updateNickname(String nickname) {  
        this.nickname = nickname;  
    }  
}
```

위 코드는 `Porring` 프로젝트에서 실제로 사용 중인 `Account` 엔티티의 관계 테이블에 대한 엔티티이다.

이름이 `Follow` 지만, `Account` 간의 관계 테이블 역할을 하면서, 동시에 관계 자체에 대한 의미를 지니는 엔티티이다.

현재 MVP 개발 단계에서 실제로 관계 자체에 대한 유즈 케이스가 늘어날 수록 이 엔티티를 확장하기만 하면 되므로 기능 확장하기가 편했다.

MVP 이후 운영 단계에서 컬럼이 추가(되면 안되겠지만,,?!)해줬으면 하는 일이 생긴다면 아예 관계 테이블을 만드는 것보다, 이렇게 엔티티를 확장하는 것이 오류가 일어날 확률은 확실히 적으리라 생각한다!
### 중간 테이블에 대한 쿼리 제어 가능

또한 중간 테이블에 대한 쿼리 제어가 된다.

얼마전 학교 친구와의 이야기에서 `Cascade.REMOVAL` 의 치명적인 오류를 알게 됐다.

`N 대 다` (N = 1 혹은 다) 에서 `Cascade.REMOVAL` 로 자식 엔티티를 지우게 되면 직접 조회하며 지우게 된다. 이때 조회/삭제 쿼리를 N번 반복하게 되어 `N+1` 문제가 생긴다는 주제였다.

관계 테이블을 조절하는 것이 **온전히** JPA 에게로 넘어가니까 이런 일에 대한 비효율이 생겨도 어찌할 수가 없는 경우가 생긴다.

중간테이블이 생긴다면, 이 관계 자체에 대한 직접적인 조작이 필요할 경우 유즈케이스에 따라 내가 원하는 쿼리를 수행시킬 수 있는 장점이 있다.

### `orphanRemoval` 사용이 불가능해짐

`@ManyToMany` 에서는 `orphanRemoval` 옵션이 지원되지 않는다.

이 옵션은 기본적으로 부모 엔티티와 연관관계가 끊어진 자식 엔티티의 관계를 알아서 삭제할 수 있도록 해준다.

```java
// orphanRemoval에 대한 예시

// Board 엔티티에서 orphanRemoval 설정
@Entity
public class Board {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String title;
    
    // orphanRemoval = true 설정으로 관계가 끊어지면 BoardTag 엔티티도 함께 삭제됨
    @OneToMany(mappedBy = "board", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<BoardTag> boardTags = new HashSet<>();
    
    // 게시글의 모든 태그 관계를 제거하는 메서드
    public void clearTags() {
        // 이 메서드 호출로 모든 관계가 제거되면 orphanRemoval에 의해 
        // 연관된 BoardTag 엔티티들도 DB에서 자동으로 삭제됨
        boardTags.clear();
    }
}

// 사용 예시 (서비스에서)
@Transactional
public void removeAllTagsFromBoard(Long boardId) {
    Board board = boardRepository.findById(boardId).orElseThrow();
    
    // boardTags 컬렉션만 비워도 orphanRemoval 설정으로 인해
    // DB의 board_tag 테이블에서 해당 board_id의 레코드들이 모두 삭제됨
    board.clearTags();
}
```

`@OneToMany` 로 `Board` 혹은 `Tag` 에서 연관된 관계만을 삭제하는 방식으로 조절하면 데이터 무결성을 지킬 수 있다.

여기서 내가 이야기하는 데이터 무결성이란 원자성에 가깝다. 서비스 코드를 작성할 때, 내가 무심코 Tag 엔티티를 담는 컬렉션만 초기화하고, 실제 관계 테이블의 관계는 삭제하지 않게 되는 경우가 있을 수 있을 것이다.

이는 내가 말하는 데이터 무결성이 지켜지지 않는 상황이고, 이런 오류는 대부분 하나의 작업을 할 때 하나의 서브 작업만 하고 이와 관련된 나머지 작업을 수행하지 않아서 일어나는 일이다.

그렇다고 해서 다른 `Cascade.REMOVAL` 등의 옵션을 사용한다고 해도 이는 `Set<Tag>` 이기 때문에 Tag 엔티티를 삭제하게되는 오류가 있을 수 있다. **이 Board 에 연관된 Tag의 관계를 삭제하시오** 가 아니라 이 **Board에 연결된 태그 자체를 삭제하시오.** 라고 되면 곤란하기 때문이다. 

그래서 보통은 관계 자체를 관리하기 위해서 `OneToMany` 를 이용해서 관계 엔티티를 참조하도록 하고, `orphanRemoval = true` 설정을 주어 관계 자체를 관리할 수 있도록 한다.

## 총 정리 : 다대다 관계 코드 예시

모든 정보를 취합하여 아래와 같이 구성할 수 있다.

아래는 클로드 예시이며, 다른 방식으로 구성될 수도 있음을 참고하자!

```java
// 게시판 엔티티
@Entity
public class Board {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String title;
    private String content;
    
    // BoardTag 관계 엔티티를 통한 Tag 접근
    // orphanRemoval을 true로 설정하여 관계가 끊어지면 BoardTag도 삭제되도록 함
    @OneToMany(mappedBy = "board", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<BoardTag> boardTags = new HashSet<>();
    
    // 편의 메서드: 태그 추가
    public void addTag(Tag tag) {
        BoardTag boardTag = new BoardTag(this, tag);
        boardTags.add(boardTag);
    }
    
    // 편의 메서드: 태그 제거
    public void removeTag(Tag tag) {
        boardTags.removeIf(boardTag -> boardTag.getTag().equals(tag));
    }
    
    // 편의 메서드: 모든 태그 갱신
    public void updateTags(Set<Tag> newTags) {
        // 기존 태그 관계를 모두 제거
        boardTags.clear();
        
        // 새로운 태그 관계 추가
        for (Tag tag : newTags) {
            addTag(tag);
        }
    }
    
    // 편의 메서드: 현재 게시판에 연결된 태그 목록 조회
    public Set<Tag> getTags() {
        return boardTags.stream()
                .map(BoardTag::getTag)
                .collect(Collectors.toSet());
    }
}

// 태그 엔티티
@Entity
public class Tag {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(unique = true)
    private String name;
    
    // 양방향 관계를 위한 BoardTag 참조
    @OneToMany(mappedBy = "tag")
    private Set<BoardTag> boardTags = new HashSet<>();
    
    // 이 태그가 사용된 게시판 목록 조회
    public Set<Board> getBoards() {
        return boardTags.stream()
                .map(BoardTag::getBoard)
                .collect(Collectors.toSet());
    }
}

// 관계 엔티티 (중간 테이블 역할)
@Entity
@Table(name = "board_tag")
public class BoardTag {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "board_id")
    private Board board;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tag_id")
    private Tag tag;
    
    // 관계에 추가적인 정보를 저장할 수 있음
    private LocalDateTime taggedAt;
    
    // 관계에 대한 메타데이터 (예: 누가 태그했는지)
    private String taggedBy;
    
    protected BoardTag() {}
    
    public BoardTag(Board board, Tag tag) {
        this.board = board;
        this.tag = tag;
        this.taggedAt = LocalDateTime.now();
    }
    
    public BoardTag(Board board, Tag tag, String taggedBy) {
        this(board, tag);
        this.taggedBy = taggedBy;
    }
    
    // Getter 메서드
    public Board getBoard() { return board; }
    public Tag getTag() { return tag; }
    public LocalDateTime getTaggedAt() { return taggedAt; }
    public String getTaggedBy() { return taggedBy; }
    
    // 태그 메타데이터 업데이트
    public void updateTaggedBy(String taggedBy) {
        this.taggedBy = taggedBy;
    }
    
    // equals & hashCode 구현
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BoardTag boardTag = (BoardTag) o;
        return Objects.equals(board.getId(), boardTag.board.getId()) &&
               Objects.equals(tag.getId(), boardTag.tag.getId());
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(board.getId(), tag.getId());
    }
}

// 서비스 계층에서의 CRUD 예시
@Service
@Transactional
public class BoardService {
    private final BoardRepository boardRepository;
    private final TagRepository tagRepository;
    private final BoardTagRepository boardTagRepository;
    
    // 생성자 주입
    public BoardService(BoardRepository boardRepository, 
                        TagRepository tagRepository,
                        BoardTagRepository boardTagRepository) {
        this.boardRepository = boardRepository;
        this.tagRepository = tagRepository;
        this.boardTagRepository = boardTagRepository;
    }
    
    // 게시글 생성 및 태그 추가
    public Board createBoard(String title, String content, List<String> tagNames, String username) {
        Board board = new Board();
        board.setTitle(title);
        board.setContent(content);
        
        // 게시글 저장
        board = boardRepository.save(board);
        
        // 태그 처리
        for (String tagName : tagNames) {
            // 기존 태그가 있으면 사용, 없으면 생성
            Tag tag = tagRepository.findByName(tagName)
                    .orElseGet(() -> {
                        Tag newTag = new Tag();
                        newTag.setName(tagName);
                        return tagRepository.save(newTag);
                    });
            
            // 중간 엔티티를 통한 관계 설정
            BoardTag boardTag = new BoardTag(board, tag, username);
            board.getBoardTags().add(boardTag);
        }
        
        return boardRepository.save(board);
    }
    
    // 게시글의 태그 목록 업데이트
    public Board updateBoardTags(Long boardId, List<String> tagNames, String username) {
        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new EntityNotFoundException("Board not found"));
        
        // 기존 태그 관계 모두 삭제 (orphanRemoval=true로 설정했으므로 자동으로 DB에서도 삭제됨)
        board.getBoardTags().clear();
        
        // 새 태그 추가
        for (String tagName : tagNames) {
            Tag tag = tagRepository.findByName(tagName)
                    .orElseGet(() -> {
                        Tag newTag = new Tag();
                        newTag.setName(tagName);
                        return tagRepository.save(newTag);
                    });
            
            BoardTag boardTag = new BoardTag(board, tag, username);
            board.getBoardTags().add(boardTag);
        }
        
        return boardRepository.save(board);
    }
    
    // 특정 태그가 달린 게시글 목록 조회
    public List<Board> getBoardsByTag(String tagName) {
        Tag tag = tagRepository.findByName(tagName)
                .orElseThrow(() -> new EntityNotFoundException("Tag not found"));
        
        // 태그의 BoardTag 관계를 통해 Board 목록 조회
        return tag.getBoardTags().stream()
                .map(BoardTag::getBoard)
                .collect(Collectors.toList());
    }
    
    // 특정 시간 이후에 태그된 게시글 목록 조회 (관계 엔티티의 추가 필드 활용)
    public List<Board> getBoardsTaggedAfter(String tagName, LocalDateTime dateTime) {
        return boardTagRepository.findByTag_NameAndTaggedAtAfter(tagName, dateTime)
                .stream()
                .map(BoardTag::getBoard)
                .collect(Collectors.toList());
    }
    
    // 특정 사용자가 태그한 게시글 목록 조회 (관계 엔티티의 추가 필드 활용)
    public List<Board> getBoardsTaggedBy(String username) {
        return boardTagRepository.findByTaggedBy(username)
                .stream()
                .map(BoardTag::getBoard)
                .collect(Collectors.toList());
    }
    
    // 게시글 삭제 (관련 태그 관계도 함께 삭제됨 - orphanRemoval)
    public void deleteBoard(Long boardId) {
        boardRepository.deleteById(boardId);
    }
}

// 관계 엔티티를 위한 Repository
@Repository
public interface BoardTagRepository extends JpaRepository<BoardTag, Long> {
    List<BoardTag> findByTag_NameAndTaggedAtAfter(String tagName, LocalDateTime dateTime);
    List<BoardTag> findByTaggedBy(String taggedBy);
    
    // 특정 Board와 Tag의 관계 조회
    Optional<BoardTag> findByBoardIdAndTagId(Long boardId, Long tagId);
    
    // 특정 Board의 모든 태그 관계 조회
    List<BoardTag> findByBoardId(Long boardId);
    
    // 특정 Tag가 사용된 모든 게시글 관계 조회
    List<BoardTag> findByTagId(Long tagId);
    
    // 특정 태그명으로 관계 조회
    List<BoardTag> findByTag_Name(String tagName);
}
```