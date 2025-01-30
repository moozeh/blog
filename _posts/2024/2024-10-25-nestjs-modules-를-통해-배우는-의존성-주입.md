---
title: Nest.js Modules 를 통해 배우는 의존성 주입
date: 2024-10-25 12:10:38 +0900
categories:
  - Backend
  - Nestjs
tags:
  - Nestjs
author: 
image: /assets/img/nest-js-image.png
---
> [!important]
> 
> 제가 몰랐던 백엔드 지식 위주로 이야기 합니다.
> Express, MVC 패턴에 관해 공부하고 오셔야 이해할 수 있습니다.

Express 를 배우고, 보다 좀 더 정형화된 형식이 필요함을 느꼈다. 

코드를 보다 견고하게 짜는 것에 대한 욕심이 생겼고, 에러 처리 등 다양한 예외 처리 로직들을 수행해보면서, 코드의 안정성이 중요하다는 걸 느꼈다.

그래서 이번에 Nest.js 를 배우기 시작했는데, `Controller` `Service` 등등.. 유명한 계층은 내가 아는 일들을 그대로 수행하고 있어서 배우는데 문제가 없었다.

그런데, 왜 `@Module` 데코레이터라는 계층이 있는 걸까? 궁금해져서 조금 알아보았다.
## 🍀 Module 이란 어떤 역할을 할까?
## 💉 의존성 주입이란 무엇일까

내가 잘못 알고 있었던 지식이 있었다.
나는 여태까지 의존성 주입이 사용자가 어떤 모듈을 굳이 `import` 하는 구문 자체가 개발자에게 책임이 있다고 잘못 이해하고 있었다.

### 의존성 주입의 정의

의존성 주입은 살짝 다르다. **구현체는 그대로 두되, 실제 내부 구현을 우리가 다양한 방식으로할 수 있게끔 하는 것이다.**

이게 무슨 뜻이냐면, 특정 클래스가 가진 메서드 (반환 타입까지) 가 정의된 스펙만을 지키면 그 내부 구조는 우리가 마음대로할 수 있는 것이다.

스펙 자체만을 정의하고, 우리는 그걸 쓰기만 하는 것이다.  그렇게된다면 협업에 있어서 효용성이 생기면서 동시에 타입 정의도 할 수 있을 거라 생각했다.

그래서 궁금한 점이, 결국엔 Nest에서는 자체적인 스펙을 정의해두는 타입 명시 클래스가 있어야하지 않을까?

스펙 자체를 한번 더 구현을 하여 구현을 두번해야한다고 생각하면, 어딘가 불편할 것 같다고 생각했는데, 제어의 역전이란 의미 자체를 내가 잘못 이해하고 있었다.

### 제어의 역전의 정의

의존성 주입 시스템에게 `이 클래스의 인스턴스 들을 관리해주세요` 라고 생각하는게 옳다. 

각각의 의존성의 정의를 주입 받는 클래스 내에서 `new` 생성자를 호출할 게 아니라, 의존성 시스템에서 직접 인스턴스를 만들어서 `주입` 시켜주는 것이 핵심이다.

그렇게 된다면, `싱글턴` 패턴을 만들 수 있는 것 아닌가? 라고 생각할 수 있다.

그 부분의 경우 우리가 유동적으로 조절해줄 수 있는 것이다. 

### 싱글턴과 차이점

1. 유연성 
	- 필요에 따라 해당 인스턴스의 범위를 내가 정의할 수 있는게 크다. 일종의 인스턴스 관리 툴이라고 생각하면 편할 듯하다.
	- 예를들어, `Nest` 에서 `@Injectable` 데코레이터 인자로 `scope` 값을 `REQUEST` 범위를 설정하면, 각 요청마다 새로운 인스턴스가 생성된다고도 한다.
1. 생명 주기 관리
	- Nest.js 에서는 실제로 생성을 싱글턴으로 할게 아니라, 해당 클래스가 언제 종료되고 새롭게 재생성할 수 있을지까지 별도로 관리할 수 있을 것이다.

## 🐈‍⬛ Nest의 의존성 주입 방식

그런데, 나는 여기서 이상하게 생각했다.

왜냐하면 결국 `providers` 배열을 통해 의존성 주입 대상을 전부 정의해주게 된다면, 굳이 `@Injectable` 데코레이터를 등록해야하는가? 라는 의문이 들었기 때문이다.

>  Nest 에서는 이 둘이 함께 작동하여 의존성 주입 시스템을 구성한다.

AI에게 물어보았더니, 간단한 동작 예시를 알려주었다.

아래 코드는 실제 Nest 구현체가 아니라, Nest의 동작 방식 이해를 위한 예제이다. 직접 만든다면 참고해볼 수 있을 것 같다.

```ts
class DIContainer {
  private providers = new Map();

  register(token: any, provider: any) {
    this.providers.set(token, provider);
  }

  resolve(target: any) {
    const tokens = Reflect.getMetadata('design:paramtypes', target) || [];
    const injections = tokens.map(token => this.resolve(this.providers.get(token)));
    return new target(...injections);
  }
}

function Module(metadata: { providers: any[] }) {
  return function(target: any) {
    const container = new DIContainer();
    metadata.providers.forEach(provider => {
      container.register(provider, provider);
    });
    
    // 이 부분은 실제로는 Nest.js 내부에서 처리됩니다
    target.prototype.container = container;
  }
}

@Injectable()
class UserService {
  getUsers() {
    return ['User1', 'User2'];
  }
}

@Injectable()
class UserController {
  constructor(private userService: UserService) {}

  getUsers() {
    return this.userService.getUsers();
  }
}

@Module({
  providers: [UserService, UserController]
})
class AppModule {}

// 사용 예시 (이 부분은 Nest.js에서 내부적으로 처리됩니다)
const appModule = new AppModule();
const userController = appModule.container.resolve(UserController);
console.log(userController.getUsers()); // ['User1', 'User2']
```

- Module 데코레이터를 사용할 때, 각각의 의존성 주입 컨테이너를 사용하는데, 실제 Nest.js 는 전역 의존성 컨테이너를 사용한다.
	- 대신, 전역 컨테이너의 일부로 사용된다.

### Injectable 데코레이터가 별도로 필요한 이유

providers 를 통해 export 를 할 수 있고, `Injectable` 을 통해서 내가 원하는 범위 간 의존성 전달을 해줄 수 있는 장점이 있다.

또한, 이 과정에서 내부적으로는 메타데이터에 클래스를 추가하여 의존성 타입을 정의해줄 수 있다.

마지막으로, 가독성 측면에서 해당 클래스가 주입될 수 있는 클래스임을 인지시켜주는 부분도 있다.

반대로, `providers` 만으로 의존성 주입이 될 수 없는 이유로 `@Injectable` 데코레이터를 사용하는 클래스 내에서도 의존성 주입을 사용하기 위한 것도 있다.

### Reflect를 사용하는 이유

단순히 `Map` 으로 대체될 수 없는 `Reflect` 만의 중요한 이점이 있기 때문에 사용된다.

방금 언급한 **메타 데이터에 클래스를 추가할 수 있다**는 것은 `Reflect` 를 이용하여 타입 정보를 의존성 등록 시 보존할 수 있다.

```ts
class MyService {
  constructor(private dependency: SomeDependency) {}
}

// 런타임에 타입 정보 접근 가능
const paramTypes = Reflect.getMetadata('design:paramtypes', MyService);
```

위와 같이, 런타임에 타입 정보에 접근이 가능하다.

또한, 생성자 파라미터의 타입 정보, 특정 파라미터에 적용된 커스텀 데코레이터, 클래스 자체에 적용된 데코레이터 정보 모두 런타임에 접근하고 처리할 수 있다고 한다.

```ts
@Injectable()
class ComplexService {
  constructor(
    private service1: Service1,
    @Inject('CONFIG') private config: Config,
    @Optional() private optionalService?: OptionalService
  ) {}
}
```

정리하자면, Reflect 맵을 이용하면 **타입 정보를 보존하면서 런타임에 (실제 의존성이 주입될 때) 어떤 타입 정보가 들어갈 지 타입스크립트 컴파일러가 알 수 있다.**

