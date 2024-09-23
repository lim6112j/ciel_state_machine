defmodule Benchmark do
  alias CielStateMachine.Logger
	def run( opts \\ []) do
		num_cars = Keyword.get(opts, :num_cars, 1)
		concurrency = min(Keyword.get(opts, :concurrency, 10), num_cars)
		items_per_process = div(num_cars, concurrency)
		IO.puts "benchmark testing ..."
		{time, _} =
			:timer.tc(fn ->
				0..(concurrency - 1)
				|> Enum.map(&performBench(&1 * items_per_process, items_per_process))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		# Process.sleep(1000)
		Logger.info "\n\n #### car dispatch time spent #{time}"
		{loc_time, _} =
			:timer.tc(fn ->
				0..(concurrency  - 1)
				|> Enum.map(&performUpdateBench(&1 * items_per_process, items_per_process))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		 Process.sleep(5000)
		Logger.info "\n\n ### car loc updated time spent #{loc_time}"
	end
	defp performBench(start_item, items_per_process) do
		Task.async(fn ->
			add_vehicle(start_item, start_item + items_per_process)
		end)

	end
	defp add_vehicle(end_item, end_item), do: :ok
	defp add_vehicle(start_item, end_item) do
		CielStateMachine.Store.dispatch(%{type: "ADD_VEHICLE"}, start_item )
		add_vehicle(start_item + 1, end_item)
	end

	defp performUpdateBench(start_item, items_per_process) do
		Task.async(fn ->
			update_vehicle(start_item, start_item + items_per_process)
		end)
	end
	defp update_vehicle(end_item, end_item), do: :ok
	defp update_vehicle(start_item, end_item) do
		CielStateMachine.Store.dispatch(
			%{type: "UPDATE_CAR_LOCATION"} ,
			[{start_item, %{lng: 127, lat: 37}}]
		)
		update_vehicle(start_item + 1, end_item)
	end

end
