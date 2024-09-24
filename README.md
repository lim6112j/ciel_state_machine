# CielStateMachine

ciel state layer system

# install dependencies

```sh
mix deps.get
```

# how to run

iex -S mix

or

mix run --no-halt


# Business logic process

지역별, 서비스별 동일 action에 대해 다른 state 처리가 필요한 경우

config에 service를 추가하면, 해당 서비스에 해당하는 reducer만을 로드하여 서버 기동

```
config :ciel_state_machine, :business_logic, service: :test
```

이방식은 서비스별로 별도의 서버를 실행 해야한다. elixir 특성상 문제는 아닌 듯 하다.

모든 business logic dictionary는 lib/ciel_state_machine/business_logic/business_logic.ex에서 정의된다.

여기에 정의된 비즈니스 키를 config에서 세팅함으로써 비즈니스 로직이 결정된다.


# how to handle business logic

reducer를 별도로 관리한다. action은 같고 reducer에 의해 처리되는 로직이 다르다.

추가되는 action이 있을 수도 있으나, 문제 없을 듯.

e.g. 서비스 지역별 비즈니스 로직이 다르면

busan_reducer를 만들고 store 실행시 busan_reducer만 추가해서 실행한다.

e.g. version별로 비즈니스 로직이 다르면

v1_reducer, v2_reducer를 각 구성하고 store실행시 선택해서 실행한다.


type 1: 단일한 서비스 시나리오만을 처리하고, 별도 지역이나 버전은 새로운 서버를 실행해얀한다.

또는

type 2 : 각 reducer에 필요한 action 이름에 버전이나 지역명을 추가하는 방식 -- 여러 시나리오를 동시에 처리할 수 있다.


# generate docs

mix generate_docs


# test

MIX_ENV=test mix coveralls

# how to use

restclient 폴더 apitest 파일 참조 , curl 사용

or

iex -S mix 실행후 명령 실행

CielStateMachine.Store.dispatch( %{type: "ADD_VEHICLE"}, 1) // supply_idx = 1 state에 추가, 추가되면서 server가 실행됨.

Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 1}) // process registry에서 supply_idx 1인 server pid 를 구함.

CielStateMachine.Store.get_state  // 현재 state를 확인 (supply list , demand list), 디테일한 정보는 각 server가 가지고 있음.

CielStateMachine.Server.add_entry(1, %{waypoints: [1,2,3]}) // supply_idx = 1인 차량의 waypoints 추가


CielStateMachine.Server.get_state(1) // 1 차량의 state 확인

CielStateMachine.Store.dispatch(%{type: "UPDATE_CAR_LOCATION"}, [{1, %{lng: 127, lat: 37}}]) // 1 차량의 current_loc 업데이트

CielStateMachine.Store.dispatch(%{type: "SET_WAYPOINTS"}, [{1, [1,2,3]}]) // 1 차량의 waypoints [1,2,3]으로 변경.

Registry.select(CielStateMachine.ProcessRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])  // all registry keys

# Milestone:
- 지금은 매번 waypoints 을 서비스 api 에서 받지만, waypoints 를 core api 에서 관리를 하거나 최적화를 하게 한다. (차량 상태가 변경되었을수 도 있으니까)
- 배차가능시간의 유효기간(무효화) 정하기 15초 ~ 1분?
-

# Rabbit_MQ - where to use??

iex -S mix
Consumer.start_link
Publisher.start_link

# Benchmark

mix run -e "Benchmark.run(num_cars: 1000, concurrency: 5)"
