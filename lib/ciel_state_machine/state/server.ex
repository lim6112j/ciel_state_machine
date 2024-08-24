defmodule CielStateMachine.Server do
  use GenStage, restart: :temporary

  def start_link(state_id) do
    IO.puts("starting server with state_id : #{state_id}")
    GenStage.start_link(__MODULE__, state_id, name: via_tuple(state_id))
  end

  def add_entry(state_id, new_entry) do
    GenServer.cast(via_tuple(state_id), {:add_entry, new_entry})
  end

  def entries(state_id) do
    GenServer.call(via_tuple(state_id), {:entries})
  end

  def get_state(state_id) do
    GenServer.call(via_tuple(state_id), {:get_state})
  end

  def update_location(state_id, loc) do
    GenServer.cast(via_tuple(state_id), {:update_location, loc})
  end

  def set_waypoints(state_id, waypoints) do
    GenServer.cast(via_tuple(state_id), {:set_waypoints, waypoints})
  end

  defp via_tuple(state_id) do
    CielStateMachine.ProcessRegistry.via_tuple({__MODULE__, state_id})
  end

  # callbacks
  def init(state_id) do
    state = CielStateMachine.Database.get(state_id) || CielStateMachine.List.new()
    {:consumer, {state_id, state}, subscribe_to: [CielStateMachine.Producer]}
  end

  def handle_cast({:add_entry, new_entry}, {state_id, state}) do
    new_state = CielStateMachine.List.add_entry(state, new_entry)
    CielStateMachine.Database.store(state_id, new_state)
    {:noreply, [], {state_id, new_state}}
  end

  def handle_cast({:update_location, loc}, {state_id, state}) do
    new_state = CielStateMachine.List.update_entry(state, loc)
    {:noreply, [], {state_id, new_state}}
  end

  def handle_cast({:set_waypoints, waypoints}, {state_id, state}) do
    new_state = CielStateMachine.List.set_waypoints(state, waypoints)
    {:noreply, [], {state_id, new_state}}
  end

  def handle_call({:entries}, _, {state_id, state}) do
    {
      :reply,
      CielStateMachine.List.entries(state),
      [],
      {state_id, state}
    }
  end

  def handle_call({:get_state}, _, {state_id, state}) do
    {
      :reply,
      state,
      [],
      {state_id, state}
    }
  end

  def handle_info(:timeout, {state_id, state}) do
    #    IO.puts("idle expire timeout, process exiting: #{state_id}")
    {:stop, :normal, {state_id, state}}
  end

  def handle_events(events, _from, {state_id, state}) do
    [event | rest] = events

    case event do
      {:update_current_loc, loc} ->
        new_state = CielStateMachine.List.update_entry(state, loc)
        {:noreply, rest, {state_id, new_state}}

      _ ->
        {:noreply, rest, {state_id, state}}
    end
  end
end
