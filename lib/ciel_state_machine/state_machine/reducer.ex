defmodule CielStateMachine.Reducer do
	@callback reduce(any,%{type: any}) :: any
end
defmodule CielStateMachine.SupplyReducer do
	@behaviour CielStateMachine.Reducer
	def reduce(nil, action), do: reduce( %{}, action)
	def reduce(state, action), do: do_reduce(state, action)
	defp do_reduce(state, action) do
		case action do
			%{type: "@@INIT"} ->
				state = %{supply_ids: [], demand_ids: []}
				IO.puts "supply reducer initializing with action @@INIT, current state = #{inspect(state)}"
				state
			%{type: "ADD_ENTRY"} ->
				IO.puts "reducing action add_entry"
				state
			_ -> state
		end
	end

end
