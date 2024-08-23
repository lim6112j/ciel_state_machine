# CielStateMachine 문서

## 목차
1. [소개](#1-소개)
2. [프로젝트 구조](#2-프로젝트-구조)
3. [핵심 구성 요소](#3-핵심-구성-요소)
4. [웹 API](#4-웹-api)
5. [주요 모듈](#5-주요-모듈)
6. [기능](#6-기능)
7. [테스트](#7-테스트)
8. [의존성](#8-의존성)
9. [시작하기](#9-시작하기)
10. [API 명세](#10-api-명세)

## 1. 소개

CielStateMachine은 차량 공급 관리를 위한 상태 머신 시스템을 구현한 Elixir 애플리케이션입니다. 이 시스템은 물류 또는 운송 애플리케이션의 백엔드로 사용될 수 있으며, Elixir의 동시성 기능을 활용하여 여러 공급 프로세스를 관리하고 웹 API를 통해 시스템과 상호작용할 수 있습니다.

## 2. 프로젝트 구조

프로젝트는 표준 Elixir 애플리케이션 구조를 따릅니다:

```
CielStateMachine/
├── lib/
│   └── ciel_state_machine/
│       ├── application/
│       ├── persistence/
│       ├── registry/
│       ├── state/
│       ├── state_machine/
│       └── web_server/
├── test/
├── .formatter.exs
├── .gitignore
├── mix.exs
├── README.md
└── rest_client/
```

## 3. 핵심 구성 요소

### 상태 머신
- SupplyReducer를 사용한 리듀서 패턴 구현
- 전역 상태 관리를 위한 중앙 집중식 저장소 (CielStateMachine.Store)
- 상태 수정을 위한 액션 디스패치 기능

### 프로세스 관리
- 개별 상태 서버 생성 및 관리를 위한 ProcessFactory 사용
- 프로세스 추적 및 접근을 위한 ProcessRegistry 사용

### 지속성
- 상태 저장 및 검색을 위한 Database 모듈
- 데이터베이스 작업자 풀 관리를 위한 poolboy 사용

## 4. 웹 API

애플리케이션은 Plug와 Cowboy를 사용하여 다음과 같은 웹 API를 제공합니다:

- POST /supply: 새로운 공급 차량 추가
- GET /supplies: 주어진 supply_idx에 대한 공급 정보 검색
- GET /v1/location/reverseGeocode: 역지오코딩 수행
- GET /v1/location/poiSearch: 지오코딩 (POI 검색) 수행

## 5. 주요 모듈

### CielStateMachine.Supervisor
- 다른 모든 프로세스를 시작하고 관리하는 메인 수퍼바이저

### CielStateMachine.Store
- 애플리케이션의 전역 상태 관리
- 상태 변경 구독 기능 제공
- 액션 디스패치 처리

### CielStateMachine.Server
- 개별 공급 엔티티에 대한 상태 서버 표현
- 단일 공급 엔티티의 상태 관리

### CielStateMachine.List
- 개별 공급 상태의 구조 및 연산 정의

### CielStateMachine.SupplyReducer
- 공급 관련 액션에 대한 리듀서 로직 구현
- 다양한 액션에 따른 공급 상태 변경 정의

### CielStateMachine.Api
- 웹 API 엔드포인트 구현
- HTTP 요청 및 응답 처리

## 6. 기능

- 공급 차량 추가 및 관리
- 차량 위치 업데이트
- 차량 경유지 설정
- 지오코딩 및 역지오코딩 기능
- 다수의 공급 프로세스 동시 처리
- 공급 상태의 지속성 유지

## 7. 테스트

프로젝트는 핵심 기능에 대한 기본적인 테스트를 포함하고 있습니다:
- ProcessFactory 테스트
- Store 및 상태 머신 테스트


## 8. 의존성

프로젝트는 다음과 같은 주요 의존성을 가집니다:

- poolboy: 작업자 풀 관리
- plug_cowboy: 웹 서버 구현
- poison: JSON 인코딩 및 디코딩
- req: HTTP 요청 수행

## 9. 시작하기

CielStateMachine 애플리케이션을 실행하려면:

1. 시스템에 Elixir가 설치되어 있는지 확인
2. 저장소 클론
3. 프로젝트 디렉토리로 이동
4. 의존성 설치: `mix deps.get`
5. 프로젝트 컴파일: `mix compile`
6. 애플리케이션 시작: `iex -S mix` 또는 `mix run --no-halt`

웹 서버는 기본적으로 5454 포트에서 시작됩니다.

개발 및 디버깅을 위해 제공된 rest_client/apitest 파일을 사용하여 API 엔드포인트를 테스트할 수 있습니다.

## 10. API 명세

State-layer 에 있는 api spec 참고 바랍니다.