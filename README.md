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
