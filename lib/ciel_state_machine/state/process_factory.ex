defmodule CielStateMachine.ProcessFactory do
	def start_link() do
		IO.puts "Starting process factory"
		DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
	end
	def child_spec(_arg) do
		%{
			id: __MODULE__,
			start: {__MODULE__, :start_link, []},
			type: :supervisor
		}
	end
	def server_process(state_id) do
		case start_child(state_id) do
			{:ok, pid} -> pid
			{:error, {:already_started, pid}} ->
				IO.puts "pid already exists"
				pid
		end
	end
	defp start_child(state_id) do
		IO.puts "starting child #{state_id}"
		DynamicSupervisor.start_child(__MODULE__, {CielStateMachine.Server, state_id})
	end
	def init(_) do
		{:ok, %{}}
	end

end
