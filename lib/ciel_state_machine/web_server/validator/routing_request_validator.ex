defmodule CielStateMachine.RoutingRequestValidator do
  def to_external_request_body(%{
    origin: origin,
    destination: destination,
    waypoints: waypoints
  }) do
    %{
      "waypoints" => Enum.map(waypoints, &to_string_coordinates/1),
      "demands" => [
        to_string_coordinates(origin),
        to_string_coordinates(destination)
      ],
      "algorithm" => 2 # TODO make it enum or string
    }
  end

  defp to_string_coordinates(%{lat: lat, lng: lng}) do
    %{
      "lat" => Float.to_string(lat),
      "lng" => Float.to_string(lng)
    }
  end

  def validate_request(%{
    "mode" => mode,
    "origin" => origin,
    "destination" => destination,
    "waypoints" => waypoints,
    "user_id" => user_id,
    "preferences" => preferences
  }) do
    with {:ok, validated_mode} <- validate_mode(mode),
         {:ok, validated_origin} <- validate_coordinate(origin),
         {:ok, validated_destination} <- validate_coordinate(destination),
         {:ok, validated_waypoints} <- validate_waypoints(waypoints),
         {:ok, validated_user_id} <- validate_user_id(user_id),
         {:ok, validated_preferences} <- validate_preferences(preferences) do
      {:ok, %{
        mode: validated_mode,
        origin: validated_origin,
        destination: validated_destination,
        waypoints: validated_waypoints,
        user_id: validated_user_id,
        preferences: validated_preferences
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  def validate_request(_), do: {:error, "Invalid request format"}

  defp validate_mode(mode) when mode in ["car", "walking"], do: {:ok, mode}
  defp validate_mode(_), do: {:error, "Invalid mode. Must be 'car' or 'walking'"}

  defp validate_coordinate(%{"latitude" => lat, "longitude" => lon}) when is_number(lat) and is_number(lon) do
    {:ok, %{lat: lat, lng: lon}}
  end
  defp validate_coordinate(_), do: {:error, "Invalid coordinate format"}

  defp validate_waypoints(waypoints) when is_list(waypoints) do
    Enum.reduce_while(waypoints, {:ok, []}, fn waypoint, {:ok, acc} ->
      case validate_coordinate(waypoint) do
        {:ok, validated} -> {:cont, {:ok, [validated | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  defp validate_waypoints(_), do: {:error, "Waypoints must be a list"}

  defp validate_user_id(user_id) when is_binary(user_id), do: {:ok, user_id}
  defp validate_user_id(_), do: {:error, "Invalid user_id format"}

  defp validate_preferences(%{
    "avoidStartPoint" => avoid_start_point,
    "avoidHighways" => avoid_highways,
    "prioritizeWaitTime" => prioritize_wait_time
  }) when is_boolean(avoid_start_point) and is_boolean(avoid_highways) and is_boolean(prioritize_wait_time) do
    {:ok, %{
      avoid_start_point: avoid_start_point,
      avoid_highways: avoid_highways,
      prioritize_wait_time: prioritize_wait_time
    }}
  end
  defp validate_preferences(_), do: {:error, "Invalid preferences format"}
end