defmodule CielStateMachine.Supervisor do
	def start_link do
		Supervisor.start_link([
			CielStateMachine.ProcessRegistry,
			CielStateMachine.Database,
			CielStateMachine.ProcessFactory,
			CielStateMachine.Api
		], strategy: :one_for_one)
	end
end
