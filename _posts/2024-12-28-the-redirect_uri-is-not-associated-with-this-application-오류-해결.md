---
title: "The redirect_uri is not associated with this application 오류 해결"
date: 2024-12-28 23:04:54 +0900
categories: [Backend, OAuth]
tags: [Backend, OAuth, Github]
---
블로그 설명 글 등에서 OAuth 앱에서 `URI` 를 설정할 때  왜 [`localhost:8080`](http://localhost:8080) 등으로 로컬 호스트로 설정을 해두었는지 알 수 있게 된 문제 해결 과정이었습니다.

`URI` 설정을 잠깐 바꾸었다가 `OAuth` 요청을 보냈는데, 해당 오류페이지로 리다이렉팅되는 문제가 있었다. 이는 실제로 `callback` uri와 실제 리디렉션 URI 가 일치하지 않을때 발생하는 문제였습니다.

이는 OAuth 에서는 XSS 등의 웹 공격을 방지하기 위해 깃허브로부터 OAuth 요청을 할 때, 우리 사이트를 통해 OAuth 를 한 후 어떤 사이트 (혹시나 해킹사이트로 가지진 않을지)에 대한 방어책이었습니다.

만약에 악의적으로 누군가가 우리의 OAuth 앱을 이용해서, 가짜 사이트에서 진짜 OAuth만 사용하고 다시 가짜사이트로 리다이렉팅할 수 있다고 생각할 수 있는 것입니다.

![[Pasted image 20241228230539.webp]]
_위 에러의 상황을 그림으로 표현_

사실 이의 경우 `client ID 토큰`까지 알아내야 가능한 일이겠지만, 클라이언트에게 `이런 이런 URI를 통해 깃허브로 가세요` 라면서 URI를 보내줄 때 `client id` 토큰이 들어있으므로 충분히 노출될 수 있겠다고 생각했습니다.

그래서 `URI`를 저희가 로컬에서 테스트하고 있었을 때에는 [`http://localhost:3000`](http://localhost:3000) 을 사용 중이었고, 별도의 데브서버용 OAuth 앱을 만들어서 해당 링크를 통해 정확하게 일치하게 프로토콜, 도메인을 일치시켜주니 문제가 해결되었습니다.