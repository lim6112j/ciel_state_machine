defmodule CielStateMachine.Producer do
	use GenStage
	def start_link do
		GenStage.start_link(__MODULE__, 0, name: __MODULE__)
	end
	def init(counter) do
		{:producer, counter}
	end
	def child_spec(_) do
		Supervisor.child_spec(
			Registry,
			id: __MODULE__,
			start: {__MODULE__, :start_link, []}
		)
	end
	def add(events) do
		GenServer.cast(__MODULE__, {:add, events})
	end
	def handle_cast({:add, events}, state) when is_list(events) do
		{:noreply, events, state}
	end

	def handle_demand(_demand, state) do
		{:noreply, [], state}
	end

end
