defmodule CielStateMachine.List do
	defstruct next_id: 1, entries: %{}, current_loc: %{}, waypoints: []
	def new(entries \\ []) do
		Enum.reduce(
			entries,
			%CielStateMachine.List{},
			&add_entry(&2, &1)
		)
	end
	def add_entry(state, entry) do
		entry = Map.put(entry, :id, state.next_id)
		new_entries = Map.put(state.entries, state.next_id, entry)
		%CielStateMachine.List{state | entries: new_entries, next_id: state.next_id + 1}
	end
	def update_entry(state, loc) do
		Map.put(state, :current_loc, loc)
	end
	def set_waypoints(state, waypoints) do
		Map.put(state, :waypoints, waypoints)
	end

	def entries(state) do
		state.entries |> Map.values()
	end
	def get_state(state) do
		state
	end

end
