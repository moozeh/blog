---
title: "[Nest.js] Nest.js 에서의 DTO"
date: 2024-10-23 18:46:23 +0900
categories:
  - Backend
  - Nestjs
tags:
  - Backend
  - Nestjs
author: 
image: /assets/img/nest-js-image.png
---

## DTO 란?

이전에 계층 간 데이터 교환을 위한 객체라고 배웠다.

여기에 더 나아가서, `DTO`란, `네트워크` 를 통해 전송되는 방법 또한 정의할 수 있다.

말 그대로 데이터 전송 객체이다.

### Nest.js 에서의 DTO

Nest.js 에서는 `Class` 를 이용하여 정의하는 것을 추천하고 있으며, `interface` 로도 가능하다.

그 이유는 `class` 는 `interface` 와 달리, 런타임 내에 정의 되어 있기 때문에 `pipe` 등의 기능도 활용 가능하다고 한다.

> 이는 **반대로 얘기하면, 굳이 상태를 보존할 이유가 없다면 인터페이스를 쓰는게 낫다는 뜻으로도 해석할 수 있겠다.**

## DTO의 역할

DTO의 역할은 크게 두가지 이다.

1. 데이터의 유효성 체크
2. 타입스크립트에서의 타입으로 활용
3. 프로퍼티 변경의 단순화

여러 계층에서 여러개의 데이터를 보내는 형식이 될 때 이를 하나의 객체로 정의하여 프로퍼티의 변경이 필요할 때,
여러 계층에서 수정해야할 때 되게 귀찮은데, 이 문제를 해결해줄 수 있다.

> [!note] 내가 이전에 배웠던 점과의 차이
>
> 이전에 내가 공부하기를 엔티티와 대응시켜 DB와 분리하는 쪽으로 DTO를 구현했지만,
> 
> 실제로 메서드마다 사용하는 DTO를 따로 정의할 수도 있다. 굳이 하나만 만들 필요는 없단 점을 생각 못했다.
> 즉, 하나의 모듈(도메인) 내에서 DTO를 꼭 하나로 통일할 필요가 없다.

## DTO 사용하기 예시

DTO 자체도 단순히 모델을 정의하듯이 정의하면 된다.

```ts:create-board.dto.ts
export class CreateBoardDto {
    title: string;
    description: string;
}
```

이 DTO를 실제 사용할 때에는 아래와 같이 사용하면 된다.

```ts:boards.controller.ts
@Post()
@UsePipes(ValidationPipe)
createBoard(@Body() createBoardDto: CreateBoardDto): Board {
	return this.boardsService.createBoard(createBoardDto);
}
```