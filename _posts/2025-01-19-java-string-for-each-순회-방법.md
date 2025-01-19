---
title: "[Java] String for-each 순회 방법"
date: 2025-01-19 15:22:10 +0900
categories:
  - Java
tags:
  - Java
---
Java에서는 스트링 순회를 어떻게 할까?

## 기존 C++ 에서의 스트링 순회 방법

**C++** 에서는 `char` 형으로 스트링을 순회할 수 있다.

(std string 기준)

```cpp
for(char t : str1) cout<<t;
```

## Java 에서 단순히 for-each를 할 경우

하지만 위와 같은 방법을 사용한다면 아래와같은 에러를 받게 된다.

![[Java String 순회-20250119151419115.webp|411]]

위와같은 에러를 받지 않게 하려면 이렇게 해야한다.

그 이유는 `const char*` 형으로 저장되는 C 기존 문자열 구현과 연관이 있습니다.

기본적으로 `std::string` 에서 제공하는 `Iterable` 옵션을 Java에서 지원해주지 않으므로 생기는 문제입니다.

Java에서는 String 클래스는 내부적으로 문자들의 배열을 private 필드로 가지고 있으며, 이는 불변(immutable) 속성으로 저장되어 있습니다.

Java 9 이전에는 char\[\] 배열을 사용했고, Java 9 이후에는 byte\[\] 배열과 인코딩 정보를 저장하는 coder 필드를 사용합니다.

## String에서 for-each 문 사용불가능한 이유

String 클래스는 `Iterable<Character>` 인터페이스를 구현하지 않았기 때문에 for-each 문법을 직접 사용할 수 없습니다.
즉, 위에서 언급한대로, `Iterable` 에 대한 행동 구현이 명시되지 않아서 그렇습니다.

또한, String은 **String Pool이라는 특별한 메모리 영역에서 관리**되며, **문자열 리터럴을 재사용하여 메모리를 최적화**합니다

```java
String str1 = "Hello";
String str2 = "Hello"; // 같은 문자열은 String Pool에서 재사용
```

가령 위와같은 str1 이 동일한 문자열을 가지고 있다면, `String Pool` 에서 같은 객체를 참조하게 함으로써 메모리를 절약합니다.

**그렇기 때문에, Java에서는 문자들의 배열을 불변객체로 저장하고 있습니다.**

## Java에서 스트링 순회 방법

따라서, `Iterable` 이 가능한 객체를 새로 만들어주어야합니다.

`String.toCharArray()` 메소드를 사용하여 새롭게 객체를 생성하는 식으로 하면 문제를 해결할 수 있습니다.

```java
for (char c : str.toCharArray()) {
    System.out.print(c);
}
```