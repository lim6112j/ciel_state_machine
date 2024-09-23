defmodule Benchmark do
  alias CielStateMachine.Logger
	def run( opts \\ []) do
		num_cars = Keyword.get(opts, :num_cars, 1)
		IO.puts "benchmark testing ..."
		{time, _} =
			:timer.tc(fn ->
				0..(num_cars - 1)
				|> Enum.map(&performBench(&1))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		# Process.sleep(1000)
		Logger.info "\n\n #### car dispatch time spent #{time}"
		{loc_time, _} =
			:timer.tc(fn ->
				0..(num_cars  - 1)
				|> Enum.map(&performUpdateBench(&1))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		# Process.sleep(5000)
		Logger.info "\n\n ### car loc updated time spent #{loc_time}"
	end
	defp performBench(supply_idx) do
		Task.async(fn ->
			CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"} , supply_idx)
		end)

	end
	defp performUpdateBench(supply_idx) do
		Task.async(fn ->
			CielStateMachine.Store.dispatch(
				%{type: "UPDATE_CAR_LOCATION"} ,
				[{supply_idx, %{lng: 127, lat: 37}}]
			)
		end)
	end

end
