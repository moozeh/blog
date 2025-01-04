---
title: "Factory Method 패턴 살펴보기"
date: 2024-03-16
description : "`react-diagrams` 에서 커스텀 노드를 만들일이 생겨 커스텀 노드 패턴을 알아보던중 엥? Factory? 리액트에선 분명 deprecated 됐을텐데… 뭔가 이상하다 싶어서 알아보았고, 리액트의 그것을 사용하는게 아닌 정말로 디자인 패턴이라는 것을 알게 되었다."
---
# Factory Method 패턴 살펴보기

`react-diagrams` 에서 커스텀 노드를 만들일이 생겨 커스텀 노드 패턴을 알아보던중 엥? Factory? 리액트에선 분명 deprecated 됐을텐데… 뭔가 이상하다 싶어서 알아보았고, 리액트의 그것을 사용하는게 아닌 정말로 디자인 패턴이라는 것을 알게 되었다.

우선 결론부터 말하자면, 팩토리 패턴이 말이 어려울 뿐이지 실제론 아무것도 아니다. 

## 생각해보기

우리가 특정 함수로 여러가지의 클래스를 기반으로 하는 객체를 생성한다고 치자. 예를들어, 동물 클래스를 상속하는 고양이, 개, 여우 의 클래스를 생성하는 생성 함수가 있다고 생각해보자.

가장 기본적인 방법은 그냥 부모클래스로 객체를 생성한 후에, 들어온 타입에 따라 값을 수정해주는 방법이 있겠다. 또는 타입에 따라 상속받은 클래스들을 `new` 생성자를 통해 뱉어주면 될것이다.

일단 전자는 추가되는 자식 클래스의 종류(동물의 종류) 가 많아질 수록 구현해야할 분량이 미친듯이 불어난다. 후자의 경우도 예외는 없다. 후자의 경우, 생성 함수가 크게 길어질 일은 없겠지만, 생성 함수 자체를 수정해야한다는 결합성에 문제가 생긴다.

## 팩토리 메소드 패턴

팩토리 메소드 패턴은 상술한 문제를 해결할 수 있는 디자인 패턴이라고 보면 된다. 팩토리 메소드 패턴을 사용하면 생성함수와 각각의 하위 클래스 간의 결합성이 많이 줄어든다. 다시 말해 생성함수를 일일이 수정할 필요가 없어진다는 뜻이다. 그렇게 된다면, 유지보수성이 크게 증가할 것이다.

애초에 생성함수 자체를 건드릴 일이 없도록 만드는 것이 팩토리 메소드 패턴의 의의라고 볼 수 있다.

### 팩토리 패턴의 주요 패러다임

1. 클래스를 생성하는 생성함수(팩토리함수) 는 공통 코드로 둔다.
2. 인스턴스를 생성하는 각 하위 클래스별 메인 코드는 하위 팩토리 클래스에서 만들도록 결정을 한다.
3. 생성한 하위 팩토리 클래스를 등록하여, 추후에 팩토리 함수로 생성할 수 있게끔 만든다.

```tsx
// AnimalFactory.ts

abstract class AnimalFactory {
  abstract createAnimal(name:string, sound:string):Animal;

	getData(name:string, sound:string): Animal {
    this.checkAnimal(); 
		const animal:Animal = this.createAnimal(name, sound);
    return animal;
	}

  checkAnimal(){
    console.log("새로운 동물을 확인해보세요~!");
  }
}

// DogFactory.ts

class DogFactory extends AnimalFactory {
  createAnimal(name:string, sound:string): Animal {
    return new Dog(name, "woof");
  }
}

// CatFactory.ts

class CatFactory extends AnimalFactory {
  createAnimal(name:string, sound:string): Animal {
    return new Cat(name, "meow meow");
  }
}
```

```tsx
// Animals.ts

class Animal {
  name?:string;
  sound?:string;
  saySound() {
    console.log(this.name + " says " + this.sound);
  }
}

// Cat.ts

class Cat extends Animal {
  constructor(name:string, sound:string) {
    super();
    this.name = name;
    this.sound = sound;
  }
  
}

// Dog.ts

class Dog extends Animal {
  constructor(name:string, sound:string) {
    super();
    this.name = name;
    this.sound = sound;
  }
}
```

이렇게 따로 생성해서 어떻게 사용하면 되냐면 하위 클래스의 팩토리 클래스의 인스턴스를 생성하여 이의 `createAnimal` 메소드를 실행시켜주는 형식으로 사용하면 된다.

```tsx
// main.ts
const dog:Dog = new DogFactory().getData("dog", "woof woof");
```

## 싱글톤 형식으로 만들어보기

매번 `new DogFatory()` 형식으로 새롭게 인스턴스를 만들어 메모리 낭비를 주는 것보단 그냥 정적 인스턴스를 받아서 사용하는 게 메모리 상으론 이득일 것이다.

```ts
// DogFactory.ts

class DogFactory extends AnimalFactory {
	private static instance: DogFactory;
	public static getInstance() {
		if(!DogFactory.instance) {
			DogFactory.instance = new DogFactory();
		}
		return DogFactory.instance;
	}
  createAnimal(name:string, sound:string): Animal {
    return new Dog(name, "woof woof");
  }
}
```