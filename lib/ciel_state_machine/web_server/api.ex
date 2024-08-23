defmodule CielStateMachine.Api do
  use Plug.Router
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison)
  plug(:dispatch)

  @port 5454
  @test_reverse_geocode_url "https://api-maps.cloud.toast.com/maps/v3.0/appkeys/6oBRFq52nuSZiAZf/addresses"
  @test_geocode_url "https://api-maps.cloud.toast.com/maps/v3.0/appkeys/6oBRFq52nuSZiAZf/coordinates"

  def child_spec(_arg) do
		IO.puts "Api server starting with cowboy..."
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

  get "/v1/location/reverseGeocode" do
    posX = Map.fetch!(conn.params, "posX")
    posY = Map.fetch!(conn.params, "posY")
    url = @test_reverse_geocode_url <> "?posX=" <> posX <> "&posY=" <> posY
    res = Req.get!(url)

    conn
    |> Plug.Conn.send_resp(200, Poison.encode!(%{response: res.body}))
  end

  get "/v1/location/poiSearch" do
    query = Map.fetch!(conn.params, "address")
    {:ok, res} = Req.get(@test_geocode_url, params: %{query: query}) # get!, get difference on response type

    conn
    |> Plug.Conn.send_resp(200, Poison.encode!(%{response: res.body}))
  end


  post "/v1/routing/direction" do
    case conn.body_params do
      %{} = params ->
        # Implement routing logic here
        # For now, we'll return a mock response
        response = %{
          resultCode: "Ok",
          result: [
            %{
              code: "Ok",
              routes: [
                %{
                  distance: 5000,
                  duration: 1200,
                  geometry: "mock_encoded_polyline",
                  legs: [
                    %{
                      distance: 5000,
                      duration: 1200,
                      summary: "Mock Route",
                      steps: [
                        %{
                          distance: 5000,
                          duration: 1200,
                          geometry: "mock_step_polyline",
                          name: "Mock Road",
                          mode: "driving",
                          instruction: "Drive straight ahead",
                          maneuver: %{
                            location: %{latitude: 37.5, longitude: 127.0},
                            type: "depart",
                            modifier: "straight"
                          },
                          intersections: []
                        }
                      ],
                      annotation: %{
                        distance: [5000],
                        duration: [1200],
                        datasource: [0],
                        nodes: [1234, 5678]
                      }
                    }
                  ],
                  weight: 1200,
                  weight_name: "duration"
                }
              ],
              waypoints: [
                %{
                  name: "Start",
                  location: %{latitude: params["origin"]["latitude"], longitude: params["origin"]["longitude"]},
                  waypointType: "break"
                },
                %{
                  name: "End",
                  location: %{latitude: params["destination"]["latitude"], longitude: params["destination"]["longitude"]},
                  waypointType: "break"
                }
              ]
            }
          ]
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(response))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{error: "Invalid request body"}))
    end
  end

  post "/v1/dispatch/available-vehicles" do
    {:ok, body, conn} = read_body(conn)
    _params = Poison.decode!(body)

    response = %{
      resultCode: "Ok",
      result: [
        %{
          vehicleId: "vehicle1",
          currentLocation: %{latitude: 37.5, longitude: 127.0},
          route: [
            %{latitude: 37.5, longitude: 127.0},
            %{latitude: 37.6, longitude: 127.1}
          ],
          etaToPickup: 10,
          etaToDropoff: 30
        }
      ]
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))

  end

  post "/v1/dispatch/request-vehicle" do
    case conn.body_params do
      %{} = _params ->
        # Implement vehicle request logic here
        # For now, we'll return a mock response
        response = %{
          resultCode: "Ok",
          result: [
            %{
              demandId: 1,
              vehicleId: "vehicle1",
              status: "Success",
              currentLocation: %{latitude: 37.5, longitude: 127.0},
              route: %{
                distance: 5000,
                duration: 1200,
                geometry: "mock_encoded_polyline",
                legs: [
                  %{
                    distance: 5000,
                    duration: 1200,
                    summary: "Mock Route",
                    steps: []
                  }
                ]
              },
              etaToPickup: 10,
              etaToDropoff: 30,
              fare: 10000,
              distanceToPickup: 2000,
              totalDistance: 5000
            }
          ]
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(response))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{error: "Invalid request body"}))
    end
  end

  post "/v1/dispatch/confirm-vehicle" do
    case conn.body_params do
      %{"demandId" => demand_id} = _params ->
        # Implement vehicle confirmation logic here
        # For now, we'll return a mock response
        response = %{
          resultCode: "Ok",
          result: [
            %{
              demandId: demand_id,
              vehicleId: "vehicle1",
              status: "Success",
              currentLocation: %{latitude: 37.5, longitude: 127.0},
              route: %{
                distance: 5000,
                duration: 1200,
                geometry: "mock_encoded_polyline",
                legs: [
                  %{
                    distance: 5000,
                    duration: 1200,
                    summary: "Mock Route",
                    steps: []
                  }
                ]
              },
              etaToPickup: 10,
              etaToDropoff: 30,
              fare: 10000,
              distanceToPickup: 2000,
              totalDistance: 5000
            }
          ]
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(response))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{error: "Invalid request body"}))
    end
  end

  get "/v1/vehicle/location" do
    vehicle_id = Map.get(conn.params, "vehicleId")

    response = %{
      resultCode: "Ok",
      result: [
        %{
          vehicleId: vehicle_id,
          location: %{latitude: 37.5, longitude: 127.0},
          speed: 50,
          heading: 90,
          altitude: 100
        }
      ]
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))
  end

  get "/v1/vehicle/state" do
    vehicle_id = Map.get(conn.params, "vehicleId")

    response = %{
      resultCode: "Ok",
      result: [
        %{
          vehicleId: vehicle_id,
          waypointId: "waypoint1",
          arrived: false,
          arrivalTime: "2024-08-23T12:00:00Z",
          estimatedStopTime: 5
        }
      ]
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))
  end

  get "/v1/vehicle/eta" do
    _vehicle_id = Map.get(conn.params, "vehicleId")

    response = %{
      resultCode: "Ok",
      result: [
        %{
          eta: "2024-08-23T12:30:00Z",
          waypointId: "waypoint1",
          reason: "Traffic conditions"
        }
      ]
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
