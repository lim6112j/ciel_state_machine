defmodule CielStateMachineTest do
  use ExUnit.Case

  setup do
    # after each test, wait for a while for subscriber log display
    on_exit(fn -> :timer.sleep(100) end)
  end

  test " processfactory create server" do
    assert is_pid(CielStateMachine.ProcessFactory.server_process(1)) == true
  end

  # test "state machine create server when needed -- sync problem" do
  #   CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, 1)
  #   regs = Registry.select(CielStateMachine.ProcessRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  #   assert length(regs) == 1
  # end

  test "state machine create server when needed -- no sync problem- subscriber with/without action" do
    CielStateMachine.Store.subscribe(
      fn _state ->
        [{pid, _}] =
          Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})
        IO.puts("\n ************ subscription called no action")
        assert is_pid(pid) == true
      end
    )
    CielStateMachine.Store.subscribe(
      fn _state, _action ->
        [{pid, _}] =
          Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})
        IO.puts("\n ************ subscription called with matched action")
        assert is_pid(pid) == true
      end,
			%{type: "ADD_VEHICLE"}
    )
    CielStateMachine.Store.subscribe(
      fn _state, _action ->
        [{pid, _}] =
          Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})
        IO.puts("\n ************ subscription called with unmatched action")
        assert is_pid(pid) == true
      end,
			%{type: "NOT_MATCHED"}
    )

    CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, 2)
  end

  test "state machine subscriber" do
    CielStateMachine.Store.subscribe(fn state ->
      IO.puts("subscriber got called with state #{inspect(state)}")
      CielStateMachine.Server.update_location(3, %{lng: 124, lat: 37})

      assert CielStateMachine.Server.get_state(3) |> Map.fetch!(:current_loc) |> Map.fetch!(:lng) ==
               124
    end)

    # supply_idx 1 vehicle add
    CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, 3)
  end
end
