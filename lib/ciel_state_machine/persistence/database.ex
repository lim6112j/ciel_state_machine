defmodule CielStateMachine.Database do
	use GenServer
  alias CielStateMachine.Logger

	@db_folder "./persist"
	def child_spec(_) do
		File.mkdir_p!(@db_folder)
		:poolboy.child_spec(__MODULE__, poolboy_config(), [@db_folder])
	end
	defp poolboy_config do
		pool_size = Application.fetch_env!(:ciel_state_machine, :worker_pool_size)
		Logger.info("worker pool size : #{pool_size}")
		[
			name: {:local, __MODULE__},
			worker_module: CielStateMachine.DatabaseWorker,
			size: pool_size
		]
	end

	def store(key, data) do
		:poolboy.transaction(__MODULE__, fn worker_pid ->
			CielStateMachine.DatabaseWorker.store(worker_pid, key, data)
		end)
	end
	def get(key) do
		:poolboy.transaction(
			__MODULE__,
			fn worker_pid ->
				CielStateMachine.DatabaseWorker.get(worker_pid, key)
			end
		)
	end
	def init(@db_folder) do
    Logger.info("Starting databse ...")
		{:ok, @db_folder}
	end

end
