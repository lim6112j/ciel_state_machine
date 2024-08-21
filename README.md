# CielStateMachine

ciel state layer system


# how to run

iex -S mix

or

mix run --no-halt

# how to use

restclient 폴더 apitest 파일 참조 , curl 사용

or

iex -S mix 실행후 명령 실행

CielStateMachine.Store.dispatch( %{type: "ADD_ENTRY"}, 1) // supply_idx = 1 state에 추가, 추가되면서 server가 실행됨.


CielStateMachine.Store.get_state  // 현재 state를 확인 (supply list , demand list), 디테일한 정보는 각 server가 가지고 있음.

CielStateMachine.Server.add_entry(1, %{waypoints: [1,2,3]} // supply_idx = 1인 차량의 waypoints 추가


CielStateMachine.Server.entries(1) // 1 차량의 state 확인
