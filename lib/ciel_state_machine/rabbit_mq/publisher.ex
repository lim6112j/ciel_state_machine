defmodule Publisher do
	use GenServer
	use AMQP
	def start_link do
		GenServer.start_link(__MODULE__, [], [])
	end
  @exchange "spring_boot_exchange"
	def init(_opts) do
    {:ok, conn} = Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = Channel.open(conn)
    :ok = Basic.publish(chan, @exchange, "", "Hello, world")
    {:ok, chan}
	end

end
