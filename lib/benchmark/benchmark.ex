defmodule Benchmark do
  alias CielStateMachine.Logger
	def run( opts \\ []) do
		num_cars = Keyword.get(opts, :num_cars, 1)
		concurrency = min(Keyword.get(opts, :concurrency, 10), num_cars)
		items_per_process = div(num_cars, concurrency)
		Logger.info "benchmark testing ..."
		{time, _} =
			:timer.tc(fn ->
				0..(concurrency - 1)
				|> Enum.map(&performBench(&1 * items_per_process, items_per_process))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		# Process.sleep(1000)
		throughput = round(num_cars * 1_000_000 /time)
		Logger.info "\n\n #### car dispatch time spent #{time / 1000} miliseconds"
		Logger.info "\n\n #### car dispatch throughput: #{throughput} operations/sec \n"
		{loc_time, _} =
			:timer.tc(fn ->
				0..(concurrency  - 1)
				|> Enum.map(&performUpdateBench(&1 * items_per_process, items_per_process))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		# Process.sleep(5000)
		update_throughput = round(num_cars * 1_000_000 / loc_time)
		Logger.info "\n\n ### car loc updated time spent #{loc_time / 1000} milliseconds"
		Logger.info "\n\n #### car loc updated throughput #{update_throughput} operations/sec \n"
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
