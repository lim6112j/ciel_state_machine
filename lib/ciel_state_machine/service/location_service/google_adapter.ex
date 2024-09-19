defmodule CielStateMachine.LocationService.GoogleAdapter do
  @base_url "https://maps.googleapis.com/maps/api"

  def reverse_geocode(latitude, longitude) do
    url = "#{@base_url}/geocode/json?latlng=#{latitude},#{longitude}&key=#{Application.get_env(:ciel_state_machine, :google_maps_api_key)}"

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        parse_reverse_geocode_response(body)
      _ ->
        {:error, "Failed to reverse geocode"}
    end
  end

  def poi_search(keyword, latitude, longitude, radius) do
    Logger.info("Application.get_env(:ciel_state_machine, :google_maps_api_key) = #{Application.get_env(:ciel_state_machine, :google_maps_api_key)}")
    url = "#{@base_url}/place/nearbysearch/json?location=#{latitude},#{longitude}&keyword=#{URI.encode(keyword)}&key=#{Application.get_env(:ciel_state_machine, :google_maps_api_key)}"
    url = if radius, do: "#{url}&radius=#{radius}", else: url

    case Req.get(url) do
      {:ok, %{status: 200, body: body}} ->
        parse_poi_search_response(body)
      _ ->
        {:error, "Failed to search POI"}
    end
  end

  defp parse_reverse_geocode_response(body) do
    # Implement parsing logic for Google's response
    # Return a map with keys matching the format_reverse_geocode_response function
  end

  defp parse_poi_search_response(body) do
    case Poison.decode(body) do
      {:ok, decoded} ->
        %{
          "resultCode" => decoded["status"],
          "result" => Enum.map(decoded["results"], fn place ->
            %{
              "id" => place["place_id"],
              "service" => "google",
              "name" => place["name"],
              "address" => place["vicinity"],
              "roadAddress" => get_road_address(place),
              "postalCode" => get_postal_code(place),
              "location" => %{
                "latitude" => place["geometry"]["location"]["lat"],
                "longitude" => place["geometry"]["location"]["lng"]
              }
            }
          end)
        }
      {:error, _} ->
        %{"resultCode" => "Error", "result" => []}
    end
  end

  defp get_road_address(place) do
    case Enum.find(place["address_components"], fn comp ->
      "route" in comp["types"]
    end) do
      nil -> ""
      component -> component["long_name"]
    end
  end

  defp get_postal_code(place) do
    case Enum.find(place["address_components"], fn comp ->
      "postal_code" in comp["types"]
    end) do
      nil -> ""
      component -> component["long_name"]
    end
  end
end