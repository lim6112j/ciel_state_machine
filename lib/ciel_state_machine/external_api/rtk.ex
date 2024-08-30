defmodule CielStateMachine.Rtk do
	use Task
	def start_link, do: Task.start_link(&loop/0)
	defp loop() do
		Process.sleep(:timer.seconds(1))
		IO.inspect(collect_current_loc())
		loop()
	end

	def child_spec(_arg) do
		%{
			id: __MODULE__,
			start: {__MODULE__, :start_link, []},
			type: :worker
		}
	end
	defp collect_current_loc() do
		randLng = :rand.uniform(360)
		randLat = :rand.uniform(90)
		[
			current_loc: %{lng: randLng, lat: randLat},
		]
	end

end
