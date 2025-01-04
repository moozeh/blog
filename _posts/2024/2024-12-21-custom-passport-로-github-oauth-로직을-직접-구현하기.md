---
title: Custom Passport 로 Github OAuth 로직을 직접 구현하기
date: 2024-12-21 12:36:32 +0900
categories:
  - Backend
  - Nestjs
tags:
  - Boostcamp
  - Backend
  - Nestjs
image: /assets/img/Pasted image 20241228230201.webp
---
## 개요

`OAuth` 가 조금 어렵다고 해서 솔직히 하루 걸릴 줄 알았습니다. 하지만 차근차근 진행해보니 수월하게 진행할 수 있었는데, 그 과정을 개발일지로 남겨주는게 좋을 것 같아 미리 남겨봅니다.

실제로 OAuth 를 예제로 만들어보는 `블로그 글` 들이 상당 수 존재하였으며, 이것들을 바탕으로 단순히 따라가기만 하면 될 것 같았습니다. 하지만 그 과정에서 이해되지 않는 부분이 존재하였고, 이 부분에서 트러블 슈팅이 조금 있었습니다. 

제가 `어떻게 OAuth를 하는지 알려주어야 앞으로 OAuth 관련 기능 구현에 있어서 도움이 될 수 있을 것이라 판단하였기에 문서로 기록하고자 합니다.`

## OAuth

### OAuth 개념

- Resource Owner : 깃허브 등 제3자 시스템에 의해 보호된 자원의 소유자 (유저)
- Client : 사용자를 대신해서 리소스에 접근하는 `서버 (저희 서비스)` 를 뜻합니다. `OAuth Client` 라고 생각하면 좋습니다.
- Resource Server : 깃허브를 가리킵니다.
- Authorization Server : 깃허브의 인증서버를 뜻합니다. OAuth 토큰을 인증하고 발급하는 역할을 합니다.

![[Pasted image 20241228230201.webp]]

### Github OAuth

깃허브에서 OAuth는 일반적으로 `조직` 혹은 `개인` 단위로 만들 수 있습니다. 또한 조직 구성원이 OAuth 앱을 만들고자 할 때는 조직의 `소유자` 에게 직접 승인을 요청해야합니다.

따라서 저희는 그냥 `제 개인 계정` 에서 OAuth 앱을 만들기로 했습니다. 

### Redirect URI, Homepage URI

이 부분에서 그냥 블로그를 따라하면서 의문이 들었던 점이 많았습니다. 일단은 결국에는 `서버의 URI` 를 따라가도록 해야합니다. 특히, `Redirect URI` 의 경우 `프로토콜까지 완전히 일치` 해야합니다. (후에 문제 해결 부분에 설명이 있습니다)

### 쿼리 스트링의 `code`의 의미

OAuth 에 성공하면 `Github` OAuth의 경우, 사전에 등록해두었던 콜백 URI에 `code` 라고 불리는 항목에 특별한 숫자를 쿼리스트링에 담아 보냅니다. 이 코드는 임시 인증 코드입니다. 인증 성공 후 `accessToken` 을 얻기 위한 중간단계로 사용됩니다. 해당 코드로 `accessToken` 을 받을 수 있습니다.

## 구현하기

실제로 구현하는데 있어서 블로그 글들을 여럿 참고하였습니다. 그중 `passport` 를 활용하는 글이 많았고, 이는 `Nest.js` 에서도 활용이 가능했기에 `passport`를 활용했습니다.

실제로 구현하는데 있어서 단순히 쓰는 것은 정말 쉬웠습니다. 블로그에서 제공되는 예시를 따르면 되었기에 일단은 이를 바탕으로 응용한 코드들을 첨부해봅니다.

```tsx
// github.strategy.ts
import { Injectable } from "@nestjs/common";
import { PassportStrategy } from "@nestjs/passport";
import "dotenv/config";
import { Profile, Strategy } from "passport-github";
import { AuthService } from "../auth.service";

@Injectable()
export class GithubStrategy extends PassportStrategy(Strategy, "github") {
    constructor(private readonly authService: AuthService) {
        super({
            clientID: process.env.OAUTH_GITHUB_ID, // CLIENT_ID
            clientSecret: process.env.OAUTH_GITHUB_SECRET, // CLIENT_SECRET
            callbackURL: process.env.OAUTH_GITHUB_CALLBACK, // redirect_uri
            passReqToCallback: true,
            scope: ["profile"], // 가져올 정보들
        });
    }

    /**
     * GitHub에서 반환된 프로필 데이터를 가공
     * @param request
     * @param accessToken
     * @param refreshToken
     * @param profile
     * @param done
     */
    async validate(
        request: any,
        accessToken: string,
        refreshToken: string,
        profile: Profile,
        done: (error: any, user?: any) => void
    ) {
        try {
            const user = await this.authService.githubLogin(profile);
            console.log(user);
            done(null, user);
        } catch (err) {
            console.error(err);
            done(err, false);
        }
    }
}

```

```tsx
// auth.controller.ts
import { Controller, Get, Redirect, Req, Res, UseGuards } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";

@Controller("auth")
export class AuthController {
    @Get("github")
    @UseGuards(AuthGuard("github"))
    async githubLogin(): Promise<void> {}

    @Get("github/login")
    @UseGuards(AuthGuard("github"))
    @Redirect()
    async githubLoginCallback(@Req() req) {
        const username: string = req.user.username;
        if (username) return { url: "/login/success/" + username };
        return { url: "/login/failure" };
    }

    @Get("protected")
    @UseGuards(AuthGuard("jwt"))
    protectedResource() {
        return "JWT is working!";
    }
}

```

### passport 에 대해 알아보기

실제로 `passport` 를 써보질 않아서 이번에 어떤 개념인지 아예 모르고 구현부터 했던 것 같습니다. 일단은 어떤 개념인지 알아야 하기 때문에 간단하게 공식 문서를 참고했습니다.

passport는 `expressjs` 에서 인증/인가 과정을 위한 미들웨어라고 합니다. 인증 인가를 위한 미들웨어인 만큼, 자체적인 `OAuth` 지원 기능도 탑재하고 있엇습니다. `passport` 에서는 기본적으로 `strategy` 라는 구현체를 이용하여 여러개의 로그인 전략을 등록하는 형식으로 로그인을 지원하고 있었습니다.

```jsx
var passport = require('passport');
var LocalStrategy = require('passport-local');

passport.use(new LocalStrategy(function verify(username, password, cb) {
  db.get('SELECT * FROM users WHERE username = ?', [ username ], function(err, user) {
    if (err) { return cb(err); }
    if (!user) { return cb(null, false, { message: 'Incorrect username or password.' }); }
    
    crypto.pbkdf2(password, user.salt, 310000, 32, 'sha256', function(err, hashedPassword) {
      if (err) { return cb(err); }
      if (!crypto.timingSafeEqual(user.hashed_password, hashedPassword)) {
        return cb(null, false, { message: 'Incorrect username or password.' });
      }
      return cb(null, user);
    });
  });
}));
```

위처럼 `LocalStrategy` 를 이용해서 `Local(자체적인)`  로그인 방식을 지원하는 미들웨어를 `passport` 자체가 `use` 하는 방식으로 등록을 할 수 있습니다.

그리고, `strategy` 의 생성자 콜백함수 `cb` 에서는 아래와 같은 형식으로 호출할 수 있습니다. 이 `cb` 함수는 마치 익스프레스에서의 `next` 함수와 대응되는 것을 볼 수 있습니다.

```jsx
return cb(null, user); // 패스워드가 맞을 경우 유저 객체 반환

return cb(null, false); // 패스워드가 맞지 않을 경우

return cb(err); // 과정에 에러가 생겼으면 에러 객체를 첫번째 인자로 반환
```

그리고 정확히! 실제로 저희 구현 코드를 보면 `validate` 함수의 콜백함수 `done` 함수와 비교가 되는 것을 볼 수 있습니다.

```jsx
async validate(
        request: any,
        accessToken: string,
        refreshToken: string,
        profile: Profile,
        done: (error: any, user?: any) => void
    ) {
        try {
            const user = await this.authService.githubLogin(profile);
            console.log(user);
            done(null, user);
        } catch (err) {
            console.error(err);
            done(err, false);
        }
    }
```

하지만 `expressjs` 임에도 `Nest.js` 에서 사용할 수 있는 이유는 무엇일까요? 이는 `auth.controller.ts` 파일에서 `githubLoginCallback` 핸들러를 보시면 알 수 있습니다. (handleGithubLogin으로 리팩토링 할 예정입니다..) `Nest.js` 에서는 미들웨어도 지원합니다.

### Nest.js 에서는 `Express 미들웨어`를 지원한다.

NestJS에서 익스프레스 미들웨어를 적용하는 방법은 세가지가 있습니다.

**1. 전역 미들웨어 적용**

main.ts에서 직접 Express 미들웨어를 적용할 수 있습니다. 코드를 보면 완전히 익스프레스와 동일한 것을 알 수 있습니다.

```tsx
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as cors from 'cors';
import * as helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Express 미들웨어 적용
  app.use(cors());
  app.use(helmet());
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  await app.listen(3000);
}
bootstrap();

```

**2. 모듈별 미들웨어 적용**

특정 모듈에서 NestModule을 구현하여 적용할 수 있습니다. 여기서 MiddlewareConsumer 라는 생소한 개념이 있는데, 이는 Nest 에서 자체적인 Middleware 클래스 를 적용할 경로, 컨트롤러 등을 지정할 수 있습니다.

`Module` 에서 여태까지 내부를 실제 구현을 한 적이 없었는데, 이때 `configure` 메서드를 통해서 어떤 미들웨어를 어떻게 사용할지 지정할 수 있습니다. 이렇게 `apply` 를 활용하여 특정 미들웨어가 어떤 경로에서 사용될지 정하게 할 수 있습니다.

```tsx
import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import * as cors from 'cors';

@Module({
  // ... 모듈 설정
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(cors())
      .forRoutes('*');  // 특정 라우트나 컨트롤러를 지정할 수 있음
  }
}

// app.module.ts
@Module({
  imports: [UsersModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(LoggerMiddleware)
      // 여러 설정 방법
      .forRoutes('users')  // 특정 경로에만 적용
      // .forRoutes(UsersController)  // 특정 컨트롤러에 적용
      // .forRoutes('*')  // 모든 경로에 적용
      // .exclude('auth')  // auth 경로 제외
      // .forRoutes({ path: 'users', method: RequestMethod.GET })  // GET 메서드만 적용
  }
}

```

**3. 커스텀 미들웨어 클래스로 래핑**

Express 미들웨어를 NestJS 미들웨어 클래스로 래핑하여 사용할 수 있습니다. 이 뜻이 무엇이냐면, expressMiddleware를 그냥 래핑해서 실행할 수 있습니다. 

```tsx
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import * as expressMiddleware from 'some-express-middleware';

@Injectable()
export class CustomMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    expressMiddleware(req, res, next);
  }
}

```

### Strategy (전략) 패턴 파헤쳐보기

그러면 이제 `passport` 를 `Nest` 에서 사용할 수 있게 됐습니다. 사실 이것들을 편하게 사용하기 위해, `Nest Module` 로 랩핑할 수 있도록 하는 `위 구현 코드 중에 `strategy`  는 무엇일까요? 그 부분을 알아내는데 조금 헤맸었고, `AI 검색` 을 통해서 빠르게 배울 수 있엇습니다.

**Passport에서의 Strategy 는 실제 전략 패턴을 구현한게 맞습니다!**

> 전략 패턴이란
> 

전략 패턴은 런타임에 알고리즘의 동작을 `선택` 하게 해주는 디자인 패턴입니다. 알고리즘을 캡슐화 해서 원하는 대로 교체를 할 수 있게 만들어줍니다. 이는 상속과는 비교되는 `구성(composition)` 을 사용하는 디자인 패턴입니다.

```tsx
// 전략 등록
passport.use(new GitHubStrategy({
    clientID: 'id',
    clientSecret: 'secret',
    callbackURL: 'callback_url'
}, verify));

// 전략 사용
app.get('/auth/github', 
    passport.authenticate('github'));
```

우리가 `use` 를 사용하는건 각각의 알고리즘 전략을 등록하는 과정입니다. 실제 저희 구현 예시에서 `AuthGuard` 에 `"github"` 문자열을 넣어둔 것은 전략 패턴을 사용하기 위함입니다.

### `passport-github` 에 대해 알아보기

그렇다면 `passport-github` 가 무엇인지 이제 이해가 가실 겁니다. `Github OAuth` 인증 방식에 대한 전략(알고리즘)들을 구현한 것입니다. 타입스크립트 사용 시 `@types/passport-github` 을 통해서 타입도 받아서 사용할 수 있습니다.

[passport-github](https://www.passportjs.org/packages/passport-github/)

위 북마크를 통해 확인해본 결과, 이 또한, `passport` 에서 자체적으로 지원해주고 있는 것으로 알고 있었습니다. 이렇게 패키지를 나눈 이유는 필요한 OAuth 인증 코드만을 들여와서 사용할 수 있도록 모듈화를 지원하기 위해서 였습니다. 이런식으로 플러그인 기능 자체를 지원해보는 것도 괜찮을 것 같다고 생각이 들었습니다. 

## Custom Passport Strategy 를 통해 SPA 에서 OAuth 사용하기

### 문제 상황

분명히 `Github` 를 활용한 OAuth는 잘 되고 있었습니다. 하지만, 콜백 을 보내주는데 뭔가 프론트엔드쪽에서 이슈가 계속 있었는데요. `CORS` 에러가 떴었습니다. 이 문제는 외부 실제로 액세스 토큰을 받아오는건 잘 됐는데 페이지 라우팅이 제대로 안되고 있었던 문제가 있었습니다.

### 문제 원인

이부분은 프론트엔드에서 생긴 문제이다보니 자칫하면 그냥 넘어갈 수 있었던 문제였습니다. 하지만 이전 학교 프로젝트에서 협업을 하면서, API나 인증쪽으로 문제가 많이 생겼던지라 걱정이 되었었고, 따라서 이번에 협업을 하면서 서버와 관련된 이슈를 계속 요청했었습니다.

알고보니, OAuth 에서 인증을 성공하면 서버 측에서 자동으로 302 요청을 보냈습니다. 이 과정에서 `CORS` 가 생겼습니다.

이는 웹서버와 API 서버를 분리했어서 일어난 일이었습니다. WAS에서 웹서버 측으로 응답 HTTP 메세지가 프록시 되어 날라가니 생기는 에러였습니다. NGINX에서 `CORS`를 허용해줄 수 있겠지만, `CORS` 헤더를 설정하는 것 자체가 조심스러웠습니다. `CORS` 관련 문제를 불필요하게 헤더를 수정하지 않고도 고치는 방법도 있지 않을까 고민했습니다.

특히나, 프론트엔드에서는 `SPA` 인 리액트를 사용하는 만큼, `302` 요청을 직접 처리하지 않고도 자연스럽게 API로써 처리될 수 있게 `API 서버` 로써의 기능을 극대화하고 싶었습니다.

### 해결 시도

`passport-github` 라이브러리를 이용해서 `302` 응답을 억제하려고 시도했지만, 불가능했습니다.

그래서 아예 외부 라이브러리를 안쓰고, 필요할 경우 자체적으로 구현해보는 것도 좋다고 느꼈습니다. 그래서 직접 `passport` 전략을 구현하려고 시도했습니다.

이때 사용한건 `passport-custom` 입니다. 이 라이브러리는 커스텀으로 전략을 만들 수 있는 `passport`의 하위 라이브러리인데, 처음부터 끝까지 개발자에게 인증전략 책임을 요구하는 라이브러리였습니다.

![[Pasted image 20241228230858.webp]]

이 과정에서 깃허브에서 OAuth 하는 과정을 알게 되었는데, 앞부분은 생략하고, 인증에 성공했을 경우 Github 측에서 콜백 URL을 통해 param으로 코드를 보냅니다.

저희는 이 코드를 이용해서 깃허브에 진짜 accessToken을 받아와줄 수 있었고, `passport-github`는 이 과정을 직접 하고 있었고, 이 코드를 깃허브로 리다이렉팅으로 보내주는 과정에서 에러가 났던 것이었습니다.

그래서 이 부분을 해결하기 위해 프론트엔드 캠퍼분과 페어프로그래밍을 진행했습니다. 코드를 서버측으로 보내고, 코드를 받은 서버는 직접 깃허브에 인증 요청을 보내 액세스토큰을 서버에서 받아오도록 수정했습니다.

```tsx
// github-auth.strategy.ts
import { Injectable, UnauthorizedException } from "@nestjs/common";
import { PassportStrategy } from "@nestjs/passport";
import { Strategy } from "passport-custom";
import { Request } from "express";
import axios from "axios";
import "dotenv/config";
import { AuthService } from "@/auth/auth.service";
import { JwtService } from "@/auth/jwt/jwt.service";

@Injectable()
export class GithubStrategy extends PassportStrategy(Strategy, "github") {
    private static REQUEST_ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token";
    private static REQUEST_USER_URL = "https://api.github.com/user";

    constructor(
        private readonly authService: AuthService,
        private readonly jwtService: JwtService
    ) {
        super();
    }

    async validate(req: Request) {
        const { code } = req.body;

        if (!code) {
            throw new UnauthorizedException("Authorization code not found");
        }

        const { access_token: accessToken } = (await this.fetchAccessToken(code)).data;

        const profile = (await this.fetchGithubUser(accessToken)).data;

        const user = await this.authService.getUserByGithubId(profile.id);
        const token = await this.jwtService.createJwtToken(user);

        return {
            jwtToken: token,
        };
    }

    private async fetchAccessToken(code: string) {
        return axios.post(
            GithubStrategy.REQUEST_ACCESS_TOKEN_URL,
            {
                client_id: process.env.OAUTH_GITHUB_ID,
                client_secret: process.env.OAUTH_GITHUB_SECRET,
                code,
            },
            {
                headers: { Accept: "application/json" },
            }
        );
    }

    private async fetchGithubUser(accessToken: string) {
        return axios.get(GithubStrategy.REQUEST_USER_URL, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
            },
        });
    }
}

```

그렇게해서 내부적으로 콜백 URL로 리액트가 움직여지면, 내부적인 API요청을 보내 액세스토큰을 받아오고, 그 후 내부적인 클라이언트 라우터로 원하는 랜딩 페이지로 이동하게끔 만들었고, 로그인 결과에 따라 성공 실패 여부를 토스트 메세지로 전송하게 만들어서 해결했습니다.

## 그 외 트러블 슈팅

[**`The redirect_uri is not associated with this application.`**](https://blog.moozeh.org/posts/the-redirect_uri-is-not-associated-with-this-application-오류-해결)

### 토큰 인증 방식과, `OAuth` 는 맞지 않는 방식일까요?

실제로 `AI 검색` 을 할 때 AI가 잘 이해하지 못하는 경우가 있는데, 내가 말을 제대로 못한 경우, 아니면 일반적인 케이스가 아닌 경우 이런 대답을 하는 경향이 있었습니다.

이는 실제로 `JWT` 토큰 인증 방식과 `OAuth` 인증 과정을 같이 지원하도록 만들고 싶어서 질문할 때에도 동일하게 대답했는데, AI가 헷갈렸던 이유가 `OAuth` 토큰 자체가 `JWT` 토큰이기 때문입니다.

결국 제가 `우리 서비스용 JWT토큰` 을 `OAuth 를 통해 깃허브로부터 받은 리소스` 로부터 `유저 테이블` 에 접근하여 관련 접속 정보를 암호화하여 클라이언트로 넘겨주면 되지 않을까? 라는 생각을 했고, 이 과정에서 테이블 설계에 대한 고민을 했던 것 같습니다.

![[Pasted image 20241228230712.webp]]

따라서 실제로 `Github 유저 정보` 로부터 `User 테이블` 을 접속하게 하기위해 `github_id` 라는 필드를 추가하여서 문제를 해결했습니다. 아래는 실제로 만든 비즈니스 로직입니다. Github 유저 정보로부터 유저가 존재하면 리턴하고, 존재하지 않는다면 이를 바탕으로 실제로 저희 서비스의 유저 엔티티를 만들어서 리턴해줍니다.

```tsx
@Transactional()
public async githubLogin(profile: Profile) {
    const user = await this.userRepository.getUserByGithubId(
        parseInt(profile.id)
    );

    if (!user)
        return await this.userRepository.createUser({
            githubId: parseInt(profile.id),
            username: `camper_${profile.id}`,
        });

    return user;
}
```



## 기술적 고민

### `accessToken` 을 언제 써야할까요?

현재 구현 방식에 따르면, `accessToken` 을 결국에는 쓸 필요가 없어집니다. `strategy` 클래스 내의 `validate` 함수에서 보면, OAuth 인증은 이미 성공했다는 가정 하에 `profile` 객체가 들어옵니다. 그렇기에 실패하면 자체적으로 유저 테이블에 유저를 새롭게 생성해주는 경우는 `저희 서비스에서 로그인에 실패한 경우` 만을 상정하고 있습니다.

현재 `accessToken` 이 필요한지 아닌지를 어떻게 생각하느냐는 저희가 어떻게 구현하느냐에 따라 다른 것으로 생각하면 됩니다.

`AI 검색` 을 통해 물어본 결과, `Github 인증` 만을 사용하는 경우 액세스토큰은 필요 없다고 합니다. 실제로 현재 `accessToken` 을 어플리케이션 내에서 저장하고 있진 않는 상황입니다.

결국, `Github 인증` → `유저 임을 인증` 하는 과정 자체만을 요구로하는 우리 서비스 특성상, `accessToken` 을 따로 저장할 필요가 없다는 뜻입니다. 실제 데이터베이스에서도 `Github 고유ID번호` 를 통해서 우리의 유저 데이터베이스에 접근할 수 있도록 만들어놨습니다.

 또한, 사용자의 깃허브 리소스에 주기적으로 접근해야하는 경우 별도로 액세스토큰이 필요합니다. 이와 같은 경우도 해당되지 않으므로 별도로 토큰을 저장할 필요가 없다고 판단하게 됐습니다.

### `Dev` 서버용 OAuth 어플리케이션을 만드는게 과연 바람직할까?

실제로 `AI 검색` 을 통해 물어본 결과 best practice 라는 답변을 들을 수 있었습니다. 하지만 과연 두개를 만들어서 관리하는게 정말 바람직할까에 대해서는 아직 잘 모르겠습니다.

- 보안성
- 독립적인 설정
- 테스트 용이성

실제로 프로덕션을 만드는 환경에서는 어떻게 할 지 고민이 될 것 같습니다. 

일단은 `.env` 파일도 `dev` 서버를 위해 공유해주는 팀원들에게는 데브용 OAuth 토큰을 공유해주고 있고, 실제 배포는 나에게 전적으로 위임되어 저 홀로 관리를 하고 있는데, 터미널을 통해 `.env` 파일을 새롭게 작성할 때에는 실제 프로덕션 환경에서 쓰이는 OAuth 앱을 사용중에 있습니다.