defmodule CielStateMachine.CombineReducers do
	def reduce(reducer_map, state, action) do
		for {state_name, reducer} <- reducer_map do
				Task.async(fn () ->
					{state_name, apply(reducer, :reduce, [state[state_name], acrion])}
				end)
		end
		|> Enum.map(&Task.await/1)
		|> Enum.into(%{})

		end

	end

end
