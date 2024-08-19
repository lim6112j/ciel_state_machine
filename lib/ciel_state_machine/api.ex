defmodule CielStateMachine.Api do
	use Plug.Router
	plug :match
	plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison)
	plug :dispatch
	@port 5454
	
	def child_spec(_arg) do
		Plug.Cowboy.child_spec(
			scheme: :http,
			options: [port: @port],
			plug: __MODULE__
		)
	end

	post "/supply" do
		{:ok, _, conn} = Plug.Conn.read_body(conn)
		IO.puts "\n encoded body: #{inspect(conn.params)}"
		name = Map.fetch!(conn.params, "name")
		name
		|> Plug.Conn.send_resp(200, "OK")
	end
	get "/supplies" do
		conn
		|> Plug.Conn.send_resp(200, Poison.encode!( %{response: "hello ciel"} ))
	end

end
