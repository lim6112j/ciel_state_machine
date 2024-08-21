defmodule Store do
	@initialize_action %{type: "@@INIT"}
	use GenServer
	def start_link(reducer, initial_state \\ nil) do
		GenServer.start_link(__MODULE__, [reducer, initial_state])
	end

	# callbacks
	def init([reducer_map, nil]) when is_map(reducer_map), do: init([reducer_map, %{}])
	def init([reducer_map, initial_state]) when is_map(reducer_map) do
		store_state = CombineReducers.reduce(reducer_map, initial_state, @initialize_action)
		{:ok, %{reducer: reducer_map, store_state: store_state, subscribers: %{}}}
	end

end
