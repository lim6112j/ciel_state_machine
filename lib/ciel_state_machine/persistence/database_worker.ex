defmodule CielStateMachine.DatabaseWorker do
	use GenServer
  alias CielStateMachine.Logger

  def start_link(db_folder) do
		GenServer.start_link(__MODULE__, db_folder)
	end
	def store(pid, key, data) do
		GenServer.cast(pid, {:store, key, data})
	end
	def get(pid, key) do
		GenServer.call(pid, {:get, key})
	end
	# callbacks

	def init(db_folder) do
		Logger.info "Starting database worker"
		{:ok, db_folder}
	end
	def handle_cast({:store, key, data}, db_folder) do
		file_name(db_folder, key)
		|> File.write!(:erlang.term_to_binary(data))
		{:noreply, db_folder}
	end
	def handle_call({:get, key}, _, db_folder) do
		data = case File.read(file_name(db_folder, key)) do
						 {:ok, contents} -> :erlang.binary_to_term(contents)
						 _ -> nil
					 end
		{:reply, data, db_folder}
	end
	defp file_name(db_folder, key) do
		"#{db_folder}/#{key}"
	end

end
