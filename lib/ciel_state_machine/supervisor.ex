defmodule CielStateMachine.Supervisor do
	def start_link do
		Supervisor.start_link([
			CielStateMachine.Producer,
			CielStateMachine.ProcessRegistry,
			CielStateMachine.Database,
			CielStateMachine.ProcessFactory,
			CielStateMachine.Api,
			CielStateMachine.Store,
		], strategy: :one_for_one)
	end
end
