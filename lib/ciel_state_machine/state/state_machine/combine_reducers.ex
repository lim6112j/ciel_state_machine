defmodule CielStateMachine.CombineReducers do
	def reduce(reducer_map, state, action, payload) do
		for {state_name, reducer} <- reducer_map do
				Task.async(fn () ->
					{state_name, apply(reducer, :reduce, [state[state_name], action, payload])}
				end)
		end
		|> Enum.map(&Task.await/1)
		|> Enum.into(%{})
		end

	end
