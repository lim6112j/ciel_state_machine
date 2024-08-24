defmodule CielStateMachineTest do
  use ExUnit.Case
  @db_folder "./persist/"
  setup do
    # after each test, remove persistence file and wait for a while for subscriber log display
    on_exit(fn ->
      File.ls!(@db_folder)
      |> Enum.each(fn item -> File.rm_rf!(@db_folder <> item) end)

      :timer.sleep(100)
    end)
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
    subscriber = fn _state ->
      [{pid, _}] =
        Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})

      IO.puts("\n ************ subscription called no action")
      assert is_pid(pid) == true
    end

    subscriber_2 = fn _state, _action ->
      [{pid, _}] =
        Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})

      IO.puts("\n ************ subscription called with matched action")
      assert is_pid(pid) == true
    end

    subscriber_3 = fn _state, _action ->
      [{pid, _}] =
        Registry.lookup(CielStateMachine.ProcessRegistry, {CielStateMachine.Server, 2})

      IO.puts("\n ************ subscription called with unmatched action")
      assert is_pid(pid) == true
    end

    ref =
      CielStateMachine.Store.subscribe(subscriber)

    ref2 =
      CielStateMachine.Store.subscribe(
        subscriber_2,
        %{type: "ADD_VEHICLE"}
      )

    ref3 =
      CielStateMachine.Store.subscribe(
        subscriber_3,
        %{type: "NOT_MATCHED"}
      )

    CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, 2)
    CielStateMachine.Store.remove_subscriber(ref)
    CielStateMachine.Store.remove_subscriber(ref2)
    CielStateMachine.Store.remove_subscriber(ref3)
    store_state = CielStateMachine.Store.get_state()
    # IO.puts("\n **** store state = #{inspect(store_state)}")

    assert store_state
           |> Map.get(:subscribers) == %{}
  end

  test "state machine subscriber and action update_car_location" do
    subscriber = fn _state, _action ->
      assert CielStateMachine.Server.get_state(2)
             |> Map.fetch!(:current_loc)
             |> Map.fetch!(:lng) == 127
    end

    ref =
      CielStateMachine.Store.subscribe(
        subscriber,
        %{type: "UPDATE_CAR_LOCATION"}
      )

    CielStateMachine.Store.dispatch(%{type: "UPDATE_CAR_LOCATION"}, [{2, %{lng: 127, lat: 37}}])
    CielStateMachine.Store.remove_subscriber(ref)
  end

  test "state machine subscriber and action set waypoints" do
    subscriber = fn _state, _action ->
      assert CielStateMachine.Server.get_state(2)
             |> Map.fetch!(:waypoints)
             |> length == 3
    end

    ref =
      CielStateMachine.Store.subscribe(
        subscriber,
        %{type: "SET_WAYPOINTS"}
      )

    CielStateMachine.Store.dispatch(%{type: "SET_WAYPOINTS"}, [{2, [1, 2, 3]}])
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

  test "server add_entry, entries test" do
    subscriber = fn _state, _action ->
      CielStateMachine.Server.add_entry("supply_idx_2", %{test: "test"})
      entries = CielStateMachine.Server.entries("supply_idx_2")
      assert entries |> Enum.at(0) |> Map.get(:test) == "test"
    end

    ref =
      CielStateMachine.Store.subscribe(
        subscriber,
        %{type: "ADD_VEHICLE"}
      )

    CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, "supply_idx_2")
    CielStateMachine.Store.remove_subscriber(ref)
  end

  test "server stop test" do
    subscriber = fn _state, _action ->
      [{pid, _}] =
        Registry.lookup(
          CielStateMachine.ProcessRegistry,
          {CielStateMachine.Server, "supply_idx_3"}
        )

      # die message send to server
      send(pid, :timeout)
      # wait for death
      Process.sleep(100)

      result =
        Registry.select(CielStateMachine.ProcessRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])

      # IO.puts "\n ***** after die message: #{inspect(result)}"

      server_key = result |> Enum.find_index(fn item -> elem(item, 1) == "supply_idx_3" end)
      assert server_key == nil
    end

    ref =
      CielStateMachine.Store.subscribe(
        subscriber,
        %{type: "ADD_VEHICLE"}
      )

    CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, "supply_idx_3")
    CielStateMachine.Store.remove_subscriber(ref)
  end
	# below test have issue. state won't be updated with get_state function
	# test "producer trigger server event-handler test" do
	# 	CielStateMachine.ProcessFactory.server_process(1)
	# 	CielStateMachine.Server.get_state(1)
	# 	CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, 1)
	# 	CielStateMachine.Producer.add([{:update_current_loc, %{lng: 12, lat: 11}}])
	# 	res = CielStateMachine.Server.get_state(1)

	# 	assert res == %{lng: 11, lat: 11}
	# end

end
