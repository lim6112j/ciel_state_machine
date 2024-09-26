defmodule Benchmark do
  alias CielStateMachine.Logger
	def run( opts \\ []) do
		num_cars = Keyword.get(opts, :num_cars, 10000)
		concurrency = min(Keyword.get(opts, :concurrency, 8), num_cars)
		num_updates = Keyword.get(opts, :num_updates, 10)
		items_per_process = div(num_cars, concurrency)
		Logger.warn "benchmark testing ... num_cars: #{num_cars}, concurrency: #{concurrency}, num_updates: #{num_updates}, items_per_process: #{items_per_process}"
		{time, _} =
			:timer.tc(fn ->
				0..(concurrency - 1)
				|> Enum.map(&performBench(&1 * items_per_process, items_per_process))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		# Process.sleep(1000)
		throughput = round(num_cars * 1_000_000 /time)
		Logger.warn "\n\n #### car dispatch time spent #{time / 1000} miliseconds"
		Logger.warn "\n\n #### car dispatch throughput: #{throughput} operations/sec \n"
		{loc_time, _} =
			:timer.tc(fn ->
				0..(concurrency  - 1)
				|> Enum.map(&performUpdateBench(&1 * items_per_process, items_per_process, num_updates))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		# for checkk log uncomment below
		# Process.sleep(5000)
		update_throughput = round(num_cars * 1_000_000 * num_updates / loc_time)
		Logger.warn "\n\n ### car loc updated time spent #{loc_time / 1000} milliseconds"
		Logger.warn "\n\n #### car loc updated throughput #{update_throughput} operations/sec \n"
		# sleep for cast methods to finish jobs
		Process.sleep(10000)
		{call_time, _} =
			:timer.tc(fn ->
				0..(concurrency - 1)
				|> Enum.map(&performGetStateCall(&1 * items_per_process, items_per_process))
				|> Enum.map(&Task.await(&1, :infinity))
			end)
		call_throughput = round(num_cars * 1_000_000 /call_time)
		Logger.warn "\n\n #### car get state call time spent #{call_time / 1000} miliseconds"
		Logger.warn "\n\n #### car get state call  call_throughput: #{call_throughput} operations/sec \n"

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

	defp performUpdateBench(start_item, items_per_process, num_updates) do
		Task.async(fn ->
			update_vehicles(start_item, start_item + items_per_process, num_updates)
		end)
	end
	defp update_vehicles(_start_item, _end_item, 0), do: :ok
	defp update_vehicles(start_item, end_item, updates) do
		update_vehicle(start_item, end_item , updates)
		update_vehicles(start_item, end_item, updates - 1)
	end

	defp update_vehicle(end_item, end_item, updates), do: :ok
	defp update_vehicle(start_item, end_item, updates) do
		CielStateMachine.Store.dispatch(
			%{type: "UPDATE_CAR_LOCATION"} ,
			[{start_item, %{lng: 127.1, lat: 37.1}}]
		)
		update_vehicle(start_item + 1, end_item, updates)
	end

	defp performGetStateCall(start_item, items_per_process) do
		Task.async(fn ->
			get_state(start_item, start_item + items_per_process)
		end)
	end
	defp get_state(end_item, end_item), do: :ok
	defp get_state(start_item, end_item) do
		state = CielStateMachine.Server.get_state(start_item)
		# Logger.warn "supply_id : #{start_item}, state: #{inspect(state)}"
		get_state(start_item + 1, end_item)
	end


end
