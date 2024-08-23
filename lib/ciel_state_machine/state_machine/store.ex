defmodule CielStateMachine.Store do
	@moduledoc """
	Store works as singleton with name __MODULE__
	state : %{reducer: %{}, state: %{}, subscribers: %{}}
	"""
	@initialize_action %{type: "@@INIT"}
	use GenServer
	def start_link(reducer, initial_state \\ nil) do
		IO.puts "state store starting with reducer : #{inspect(reducer)}"
		GenServer.start_link(__MODULE__, [reducer, initial_state], name: __MODULE__)
	end
	@doc """
	when action specified, subscription works on the specific action,

  if action == nil, all action will be triggered on the subscription.

	action specification works as filter
	"""
	def subscribe(subscriber, action \\ nil) do
		GenServer.call(__MODULE__, {:subscribe, {subscriber, action}})
	end
	def remove_subscriber(ref) do
		GenServer.cast(__MODULE__, {:remove_subscriber, ref})
	end

	def dispatch(action, payload) do
		GenServer.cast(__MODULE__, {:dispatch, action, payload})
	end
	def get_state do
		GenServer.call(__MODULE__, {:get_state})
	end

	# callbacks
	def child_spec(_arg) do
		%{
			id: __MODULE__,
			start: {__MODULE__, :start_link, [%{supply: CielStateMachine.SupplyReducer}]}
		}
	end


	def init([reducer_map, nil]) when is_map(reducer_map), do: init([reducer_map, %{}])
	def init([reducer_map, initial_state]) when is_map(reducer_map) do
		store_state = CielStateMachine.CombineReducers.reduce(reducer_map, initial_state, @initialize_action, nil)
		{:ok, %{reducer: reducer_map, store_state: store_state, subscribers: %{}}}
	end

	def handle_call({:subscribe, sub}, _from, state) do
		ref = make_ref()
		{:reply, ref,  put_in(state, [:subscribers, ref], sub)}
	end
	def handle_call({:get_state}, _from, state) do
		{:reply, state, state}
	end

	def handle_cast({:dispatch, action, payload}, state) when is_map(state.reducer) do
		store_state = CielStateMachine.CombineReducers.reduce(state.reducer, state.store_state, action, payload)
		for {_ref, sub} <- state.subscribers do
				case sub do
					{fun, nil} ->
						IO.puts "\n fun(1), action #{inspect(action)}"
						fun.(store_state)
					{fun, sub_action} when sub_action == action ->
						IO.puts "\n fun(2), action #{inspect(action)}"
						fun.(store_state, sub_action)
					_ -> :ok
				end


		end

		{:noreply, Map.put(state, :store_state, store_state)}
	end
	def handle_cast({:remove_subscriber, ref}, state) do
		subscribers = Map.delete(state.subscribers, ref)
		{:noreply, Map.put(state, :subscribers, subscribers)}
	end

end
