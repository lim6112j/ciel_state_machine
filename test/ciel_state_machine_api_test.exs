defmodule CielStateMachineApiTest do
	use ExUnit.Case, async: true
	use Plug.Test
	import Mock
	test "ping returns" do
		conn = conn(:get, "/ping")
		conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
		assert conn.state == :sent
		assert conn.status == 200
		assert conn.resp_body == "pong!"
	end
	test "unmatched url test" do
		conn = conn(:get, "/unmatched")
		conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
		assert conn.status == 404
	end
	test "supply post test" do
		conn = conn(:post, "/supply",%{supply_idx: 2, vehicle_plate_num: "54가 1111"} )
		conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
		# TODO wait for add_entry process(handle_cast), need to change to handle_call??????
		# comment this will trigger test failure
		Process.sleep(100)
		# handle call
		entries = CielStateMachine.Server.entries(2)
		#IO.puts "\n ********** after add_entry, entries = #{inspect(entries)}"
		assert conn.status == 200
		assert conn.resp_body == "OK"
		assert Enum.empty?(entries) == false
	end
	test "supply post test wrong payload" do
		conn = conn(:post, "/supply", "hello world" )
		conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
		# IO.puts "resp body = #{inspect(conn)}"
		assert conn.status == 422
	end
	test "inavi geocode test" do
		with_mock Req, [get: fn (_url, _query) -> {:ok, %{body: "{lng: 127, lat: 37}"} } end] do
			conn = conn(:get, "/v1/location/poiSearch", %{address: "서울 용산구 동자동 43-205"})
			conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
			# IO.puts "\n ******** conn in mock test = #{inspect(conn)}"
			assert conn.status == 200
			assert conn.resp_body == ~s({"response":"{lng: 127, lat: 37}"})
		end
	end
	test "inavi reverse geocode test" do
		with_mock Req, [get!: fn (_url) -> %{body: "서울 용산구 동자동 43-205"} end] do
			conn = conn(:get, "/v1/location/reverseGeocode?posX=126.9717295&posY=37.55483949")
			conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))
			# IO.puts "\n ******** conn in mock test = #{inspect(conn)}"
			assert conn.status == 200
			assert conn.resp_body == ~s({"response":"서울 용산구 동자동 43-205"})
		end
	end

  describe "POST /v1/routing/direction" do
    test "returns 200 with valid request" do
      valid_request = %{
        "mode" => "car",
        "origin" => %{"latitude" => 37.5665, "longitude" => 126.9780},
        "destination" => %{"latitude" => 37.5665, "longitude" => 126.9780},
        "waypoints" => [%{"latitude" => 37.5665, "longitude" => 126.9780}],
        "user_id" => "test_user",
        "preferences" => %{
          "avoidStartPoint" => false,
          "avoidHighways" => false,
          "prioritizeWaitTime" => false
        }
      }

      mock_external_response = %{
        "code" => "Ok",
        "routes" => [
          %{
            "distance" => 1000,
            "duration" => 300,
            "geometry" => "mock_geometry",
            "legs" => [
              %{
                "distance" => 1000,
                "duration" => 300,
                "summary" => "Mock Route",
                "steps" => [],
                "annotation" => %{
                  "distance" => [1000],
                  "duration" => [300],
                  "datasources" => [1],
                  "nodes" => [1, 2]
                }
              }
            ],
            "weight" => 300,
            "weight_name" => "duration"
          }
        ],
        "waypoints" => [
          %{
            "name" => "Start",
            "location" => [126.9780, 37.5665]
          },
          %{
            "name" => "End",
            "location" => [126.9780, 37.5665]
          }
        ]
      }

      mock_converted_response = %{
        "resultCode" => "Ok",
        "result" => [
          %{
            "code" => "Ok",
            "routes" => [
              %{
                "distance" => 1000,
                "duration" => 300,
                "geometry" => "mock_geometry",
                "legs" => [
                  %{
                    "distance" => 1000,
                    "duration" => 300,
                    "summary" => "Mock Route",
                    "steps" => [],
                    "annotation" => %{
                      "distance" => [1000],
                      "duration" => [300],
                      "datasource" => [1],
                      "nodes" => [1, 2]
                    }
                  }
                ],
                "weight" => 300,
                "weight_name" => "duration"
              }
            ],
            "waypoints" => [
              %{
                "name" => "Start",
                "location" => %{"latitude" => 37.5665, "longitude" => 126.9780},
                "waypointType" => "break"
              },
              %{
                "name" => "End",
                "location" => %{"latitude" => 37.5665, "longitude" => 126.9780},
                "waypointType" => "break"
              }
            ]
          }
        ]
      }

      with_mocks([
        {CielStateMachine.RoutingService, [],
          [
            call_external_routing_api: fn _body -> {:ok, mock_external_response} end,
            convert_response: fn _response -> mock_converted_response end
          ]}
      ]) do
        conn =
          conn(:post, "/v1/routing/direction", valid_request)
          |> put_req_header("content-type", "application/json")

        conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))

        assert conn.status == 200
        assert conn.state == :sent

        response = Jason.decode!(conn.resp_body)
        assert response["resultCode"] == "Ok"
        assert is_list(response["result"])
        assert length(response["result"]) == 1

        result = Enum.at(response["result"], 0)
        assert is_map(result)
        assert is_list(result["routes"])
        assert length(result["routes"]) == 1

        route = Enum.at(result["routes"], 0)
        assert is_map(route)
        assert route["distance"] == 1000
        assert route["duration"] == 300
        assert route["geometry"] == "mock_geometry"

        assert is_list(result["waypoints"])
        assert length(result["waypoints"]) == 2
      end
    end

    test "returns 400 with invalid request" do
      invalid_request = %{
        "mode" => "invalid_mode",
        "origin" => %{"latitude" => "invalid", "longitude" => 126.9780},
        "destination" => %{"latitude" => 37.5665, "longitude" => 126.9780},
        "waypoints" => "invalid",
        "user_id" => 123,
        "preferences" => "invalid"
      }

      conn =
        conn(:post, "/v1/routing/direction", invalid_request)
        |> put_req_header("content-type", "application/json")

      conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))

      assert conn.status == 400
      assert conn.state == :sent

      response = Jason.decode!(conn.resp_body)
      assert response["error"] != nil
    end

    test "returns 500 when external API call fails" do
      valid_request = %{
        "mode" => "car",
        "origin" => %{"latitude" => 37.5665, "longitude" => 126.9780},
        "destination" => %{"latitude" => 37.5665, "longitude" => 126.9780},
        "waypoints" => [%{"latitude" => 37.5665, "longitude" => 126.9780}],
        "user_id" => "test_user",
        "preferences" => %{
          "avoidStartPoint" => false,
          "avoidHighways" => false,
          "prioritizeWaitTime" => false
        }
      }

      with_mocks([
        {CielStateMachine.RoutingService, [],
          [
            call_external_routing_api: fn _body -> {:error, "External API error"} end
          ]}
      ]) do
        conn =
          conn(:post, "/v1/routing/direction", valid_request)
          |> put_req_header("content-type", "application/json")

        conn = CielStateMachine.Api.call(conn, CielStateMachine.Api.init([]))

        assert conn.status == 500
        assert conn.state == :sent

        response = Jason.decode!(conn.resp_body)
        assert response["error"] =~ "Routing calculation failed"
      end
    end
  end
end