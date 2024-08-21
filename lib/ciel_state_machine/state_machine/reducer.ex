defmodule CielStateMachine.Reducer do
	@callback reduce(any, %{type: any}, any ) :: any
end
defmodule CielStateMachine.SupplyReducer do
	@behaviour CielStateMachine.Reducer
	def reduce( nil, action), do: reduce( %{}, action, nil)
	def reduce(state, action, payload \\ nil), do: do_reduce(state, action, payload)
	defp do_reduce(state, action, payload) do
		case action do
			%{type: "@@INIT"} ->
				state = %{supply_ids: [], demand_ids: []}
				IO.puts "supply reducer initializing with action @@INIT, current state = #{inspect(state)}"
				state
			%{type: "ADD_ENTRY"} ->
				CielStateMachine.ProcessFactory.server_process(payload)
				supply_ids = [payload | state.supply_ids]

				new_state = %{state | supply_ids: supply_ids}
				IO.puts "state.supply_ids after add_entry : #{inspect(new_state)}"
				new_state
			_ -> state
		end
	end

end
