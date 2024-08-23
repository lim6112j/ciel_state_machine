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
    ref =
      CielStateMachine.Store.subscribe(fn _state ->
        [{pid, _}] =
          Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})

        IO.puts("\n ************ subscription called no action")
        assert is_pid(pid) == true
      end)

    ref2 =
      CielStateMachine.Store.subscribe(
        fn _state, _action ->
          [{pid, _}] =
            Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})

          IO.puts("\n ************ subscription called with matched action")
          assert is_pid(pid) == true
        end,
        %{type: "ADD_VEHICLE"}
      )

    ref3 =
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
    CielStateMachine.Store.remove_subscriber(ref)
    CielStateMachine.Store.remove_subscriber(ref2)
    CielStateMachine.Store.remove_subscriber(ref3)
    store_state = CielStateMachine.Store.get_state()
    IO.puts("\n **** store state = #{inspect(store_state)}")
    assert store_state
    |> Map.get(:subscribers) == %{}
  end

  test "state machine subscriber" do
    ref = CielStateMachine.Store.subscribe(
      fn _state, _action ->
        assert CielStateMachine.Server.get_state(2)
               |> Map.fetch!(:current_loc)
               |> Map.fetch!(:lng) == 127
      end,
      %{type: "UPDATE_CAR_LOCATION"}
    )

    CielStateMachine.Store.dispatch(%{type: "UPDATE_CAR_LOCATION"}, [{2, %{lng: 127, lat: 37}}])
		CielStateMachine.Store.remove_subscriber(ref)
  end

  test "state machine state" do
    CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, "supply_id_1")
    store_state = CielStateMachine.Store.get_state()
    assert store_state
           |> Map.get(:store_state)
           |> Map.get(:supply)
           |> Map.get(:supply_ids)
           |> Enum.any?(&(&1 == "supply_id_1")) ==
             true
  end
end
