defmodule CielStateMachineTest do
  use ExUnit.Case

  test " processfactory create server" do
    assert is_pid(CielStateMachine.ProcessFactory.server_process(1)) == true
  end
	test "state machine create server when needed" do
		CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, 1)
		regs = Registry.select(CielStateMachine.ProcessRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
		assert length(regs) == 1
	end
	test "state machine subscriber" do
		CielStateMachine.Store.subscribe(fn state ->
			IO.puts "subscriber got called with state #{inspect(state)}"
			CielStateMachine.Server.update_location(2, %{lng: 124, lat: 37})
			assert CielStateMachine.Server.get_state(2) |> Map.fetch(:current_loc) |> Map.fetch(:lng) == 124
		end
		)
		CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, 2 ) # supply_idx 1 vehicle add


	end


end
