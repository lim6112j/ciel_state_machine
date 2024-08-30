defmodule CielStateMachine.BusinessLogic do
	def businessLogics do
		%{
			test: CielStateMachine.TestReducer,
			default: CielStateMachine.SupplyReducer,
		}

	end

end
