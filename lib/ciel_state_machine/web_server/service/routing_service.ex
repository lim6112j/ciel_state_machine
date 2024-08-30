defmodule CielStateMachine.RoutingService do
  def call_external_routing_api(request_body) do
    url = Application.get_env(:ciel_state_machine, :dispatch_engine_service)[:url]
    headers = [{"Content-Type", "application/json"}]

    case Req.post(url <> "/osrm", json: request_body, headers: headers) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, "API returned status #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def convert_response(input) do
    %{
      "resultCode" => input["code"],
      "result" => [
        %{
          "code" => input["code"],
          "routes" => Enum.map(input["routes"], &convert_route/1),
          "waypoints" => Enum.map(input["waypoints"], &convert_waypoint/1)
        }
      ]
    }
  end

  defp convert_route(route) do
    %{
      "distance" => route["distance"],
      "duration" => route["duration"],
      "geometry" => route["geometry"],
      "legs" => Enum.map(route["legs"], &convert_leg/1),
      "weight" => route["weight"] || 0,
      "weight_name" => route["weight_name"] || ""
    }
  end

  defp convert_leg(leg) do
    %{
      "distance" => leg["distance"],
      "duration" => leg["duration"],
      "summary" => leg["summary"],
      "steps" => Enum.map(leg["steps"], &convert_step/1),
      "annotation" => convert_annotation(leg["annotation"])
    }
  end

  defp convert_step(step) do
    %{
      "distance" => step["distance"],
      "duration" => step["duration"],
      "geometry" => step["geometry"],
      "name" => step["name"],
      "mode" => step["mode"],
      "instruction" => step["maneuver"]["modifier"],
      "maneuver" => convert_maneuver(step["maneuver"]),
      "intersections" => Enum.map(step["intersections"], &convert_intersection/1)
    }
  end

  defp convert_maneuver(maneuver) do
    %{
      "location" => %{
        "latitude" => Enum.at(maneuver["location"], 1),
        "longitude" => Enum.at(maneuver["location"], 0)
      },
      "type" => maneuver["type"],
      "modifier" => maneuver["modifier"],
      "bearing_before" => maneuver["bearingBefore"],
      "bearing_after" => maneuver["bearingAfter"]
    }
  end

  defp convert_intersection(intersection) do
    %{
      "location" => %{
        "latitude" => Enum.at(intersection["location"], 1),
        "longitude" => Enum.at(intersection["location"], 0)
      },
      "bearings" => intersection["bearings"],
      "entry" => intersection["entry"],
      "in" => intersection["in"],
      "out" => intersection["out"],
      "indications" => ["uturn"] # Placeholder, as the original doesn't have this field
    }
  end

  defp convert_annotation(annotation) do
    %{
      "distance" => annotation["distance"],
      "duration" => annotation["duration"],
      "datasource" => annotation["datasources"],
      "nodes" => annotation["nodes"]
    }
  end

  defp convert_waypoint(waypoint) do
    %{
      "name" => waypoint["name"],
      "location" => %{
        "latitude" => Enum.at(waypoint["location"], 1),
        "longitude" => Enum.at(waypoint["location"], 0)
      },
      "waypointType" => "break" # Placeholder, as the original doesn't have this field
    }
  end

#  def transform_response(external_response) do
#    %{
#      resultCode: "Ok",
#      result: [
#        %{
#          code: "Ok",
#          routes: [
#            %{
#              distance: external_response["distance"],
#              duration: external_response["duration"],
#              geometry: external_response["geometry"],
#              legs: transform_legs(external_response["legs"])
#            }
#          ],
#          waypoints: transform_waypoints(external_response["waypoints"])
#        }
#      ]
#    }
#  end
#
#  defp transform_legs(legs) do
#    Enum.map(legs, fn leg ->
#      %{
#        distance: leg["distance"],
#        duration: leg["duration"],
#        summary: leg["summary"],
#        steps: transform_steps(leg["steps"])
#      }
#    end)
#  end
#
#  defp transform_steps(steps) do
#    Enum.map(steps, fn step ->
#      %{
#        distance: step["distance"],
#        duration: step["duration"],
#        geometry: step["geometry"],
#        name: step["name"],
#        mode: step["mode"],
#        instruction: step["instruction"],
#        maneuver: transform_maneuver(step["maneuver"])
#      }
#    end)
#  end
#
#  defp transform_maneuver(maneuver) do
#    %{
#      location: %{latitude: hd(maneuver["location"]), longitude: List.last(maneuver["location"])},
#      type: maneuver["type"],
#      modifier: maneuver["modifier"]
#    }
#  end
#
#  defp transform_waypoints(waypoints) do
#    Enum.map(waypoints, fn waypoint ->
#      %{
#        name: waypoint["name"],
#        location: %{latitude: hd(waypoint["location"]), longitude: List.last(waypoint["location"])},
#        waypointType: "break"  # Assuming all waypoints are of type "break"
#      }
#    end)
#  end
end