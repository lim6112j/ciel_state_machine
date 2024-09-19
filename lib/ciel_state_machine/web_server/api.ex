defmodule CielStateMachine.Api do
  use Plug.Router
  alias CielStateMachine.Logger
  alias CielStateMachine.RoutingRequestValidator
  alias CielStateMachine.RoutingService
  alias CielStateMachine.LocationService


  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison)
  plug(:dispatch)

  @port 5454
  @test_reverse_geocode_url "https://api-maps.cloud.toast.com/maps/v3.0/appkeys/6oBRFq52nuSZiAZf/addresses"
  @test_geocode_url "https://api-maps.cloud.toast.com/maps/v3.0/appkeys/6oBRFq52nuSZiAZf/coordinates"

  def child_spec(_arg) do
    Logger.info("Api server starting with cowboy...")
    Plug.Cowboy.child_spec(
      scheme: :http,
      options: [port: @port],
      plug: __MODULE__
    )
  end

  get "/ping" do
    Logger.debug("Received ping request")
    conn
    |> Plug.Conn.send_resp(200, "pong!")
  end

  post "/supply" do
    {:ok, _, conn} = Plug.Conn.read_body(conn)
    # Logger.info("\n encoded body: #{inspect(conn)}")
		case conn.body_params do
			%{"supply_idx" => supply_idx, "vehicle_plate_num" => vehicle_plate_num} ->
			#	CielStateMachine.ProcessFactory.server_process(supply_idx)
				dispatch_action = %{type: "ADD_VEHICLE"}
				subscriber = fn _state, _action ->
					CielStateMachine.Server.add_entry(supply_idx, %{
								supply_idx: supply_idx,
								vehicle_plate_num: vehicle_plate_num
																						})

				end
				ref = CielStateMachine.Store.subscribe(subscriber, dispatch_action)
				CielStateMachine.Store.dispatch(dispatch_action, supply_idx)
				CielStateMachine.Store.remove_subscriber(ref)
				conn
				|> Plug.Conn.send_resp(200, "OK")
			_ ->
				conn |>
					Plug.Conn.send_resp(422, Poison.encode!(%{response: "wrong params"}))
		end
  end

  get "/supplies" do
    supply_idx = Map.fetch!(conn.params, "supply_idx")
    Logger.info("supply idx from get request = #{supply_idx}")
    entries = CielStateMachine.Server.entries(supply_idx)

    conn
    |> Plug.Conn.send_resp(200, Poison.encode!(%{response: entries}))
  end

  get "/v1/location/reverseGeocode" do
    latitude = Map.fetch!(conn.params, "latitude")
    longitude = Map.fetch!(conn.params, "longitude")

    case LocationService.reverse_geocode(latitude, longitude) do
      {:ok, result} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(result))
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{error: reason}))
    end
  end

  get "/v1/location/poiSearch" do
    keyword = Map.fetch!(conn.params, "keyword")
    latitude = Map.fetch!(conn.params, "latitude")
    longitude = Map.fetch!(conn.params, "longitude")
    radius = Map.get(conn.params, "radius")

    case LocationService.poi_search(keyword, latitude, longitude, radius) do
      {:ok, result} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(result))
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{
          "resultCode" => "Error",
          "error" => reason
        }))
    end
  end

  post "/v1/routing/direction" do
    Logger.debug("Received routing direction request")
    Logger.debug("Request headers: #{inspect(conn.req_headers)}")

    {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
    Logger.debug("Raw request body: #{inspect(raw_body)}")
    Logger.debug("Parsed body params: #{inspect(conn.body_params)}")

    case conn.body_params do
      params when map_size(params) == 0 ->
        Logger.error("Empty request body")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{error: "Empty request body"}))

      params ->
        process_routing_request(conn, params)
    end
  end

  defp process_routing_request(conn, params) do
    case RoutingRequestValidator.validate_request(params) do
      {:ok, validated_params} ->
        Logger.debug("Request validation successful", validated_params: validated_params)

        external_request_body =
          CielStateMachine.RoutingRequestValidator.to_external_request_body(validated_params)

        Logger.debug("Prepared request body for external API", request_body: external_request_body)

        # Call external routing API(our dispatch service engine)
        case RoutingService.call_external_routing_api(external_request_body) do
          {:ok, external_response} ->
            Logger.debug("Received successful response from external API",
              response: external_response
            )

            converted_response = RoutingService.convert_response(external_response)

            Logger.debug("Transformed #{inspect(converted_response)} external API response",
              converted_response: inspect(converted_response)
            )

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Poison.encode!(converted_response))

          {:error, %Req.TransportError{reason: reason}} ->
            error_message = "External API call failed due to transport error: #{inspect(reason)}"
            Logger.error(error_message)

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Poison.encode!(%{error: error_message}))

          {:error, reason} ->
            error_message = "Routing calculation failed: #{inspect(reason)}"
            Logger.error(error_message)

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Poison.encode!(%{error: error_message}))
        end

      {:error, reason} ->
        Logger.error("Request validation failed", reason: reason)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Poison.encode!(%{error: reason}))
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
