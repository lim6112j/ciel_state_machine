defmodule CielStateMachine.Api do
  use Plug.Router
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison)
  plug(:dispatch)
  @port 5454
  @test_reverse_geocode_url "https://api-maps.cloud.toast.com/maps/v3.0/appkeys/6oBRFq52nuSZiAZf/addresses"
  @test_geocode_url "https://api-maps.cloud.toast.com/maps/v3.0/appkeys/6oBRFq52nuSZiAZf/coordinates"
  def child_spec(_arg) do
    Plug.Cowboy.child_spec(
      scheme: :http,
      options: [port: @port],
      plug: __MODULE__
    )
  end

  post "/supply" do
    {:ok, _, conn} = Plug.Conn.read_body(conn)
    IO.puts("\n encoded body: #{inspect(conn.params)}")
    supply_idx = Map.fetch!(conn.params, "supply_idx")
    vehicle_plate_num = Map.fetch!(conn.params, "vehicle_plate_num")
    CielStateMachine.ProcessFactory.server_process(supply_idx)

    CielStateMachine.Server.add_entry(supply_idx, %{
      supply_idx: supply_idx,
      vehicle_plate_num: vehicle_plate_num
    })

    conn
    |> Plug.Conn.send_resp(200, "OK")
  end

  get "/supplies" do
    supply_idx = Map.fetch!(conn.params, "supply_idx")
    IO.puts("supply idx from get request = #{supply_idx}")
    entries = CielStateMachine.Server.entries(supply_idx)

    conn
    |> Plug.Conn.send_resp(200, Poison.encode!(%{response: entries}))
  end

  get "/reverse_geocode" do
    posX = Map.fetch!(conn.params, "posX")
    posY = Map.fetch!(conn.params, "posY")
    url = @test_reverse_geocode_url <> "?posX=" <> posX <> "&posY=" <> posY
    res = Req.get!(url)

    conn
    |> Plug.Conn.send_resp(200, Poison.encode!(%{response: res.body}))
  end

  get "geocode" do
    query = Map.fetch!(conn.params, "address")
    {:ok, res} = Req.get(@test_geocode_url, params: %{query: query}) # get!, get difference on response type

    conn
    |> Plug.Conn.send_resp(200, Poison.encode!(%{response: res.body}))
  end
end
