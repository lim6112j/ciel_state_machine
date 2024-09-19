defmodule CielStateMachine.LocationService.NaverAdapter do
  @base_url "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2"
  @poi_search_url "https://naveropenapi.apigw.ntruss.com/map-place/v1/search"

  def reverse_geocode(latitude, longitude) do
    url = "#{@base_url}/reversegeocode?coords=#{longitude},#{latitude}&output=json"
    headers = [
      {"X-NCP-APIGW-API-KEY-ID", Application.get_env(:ciel_state_machine, :naver_map_client_id)},
      {"X-NCP-APIGW-API-KEY", Application.get_env(:ciel_state_machine, :naver_map_client_secret)}
    ]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_reverse_geocode_response(body)
      _ ->
        {:error, "Failed to reverse geocode"}
    end
  end

  def poi_search(keyword, latitude, longitude, radius) do
    url = "#{@poi_search_url}/search?query=#{URI.encode(keyword)}&coord=#{longitude},#{latitude}"
    url = if radius, do: "#{url}&radius=#{radius}", else: url

    headers = [
      {"X-NCP-APIGW-API-KEY-ID", Application.get_env(:ciel_state_machine, :naver_map_client_id)},
      {"X-NCP-APIGW-API-KEY", Application.get_env(:ciel_state_machine, :naver_map_client_secret)}
    ]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_poi_search_response(body)
      {:ok, %{status: status, body: body}} ->
        {:error, "API returned status #{status}: #{body}"}
      {:error, %{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  defp parse_reverse_geocode_response(body) do
    # Implement parsing logic for Naver's response
    # Return a map with keys matching the format_reverse_geocode_response function
  end

  defp parse_poi_search_response(body) do
    case Jason.decode(body) do
      {:ok, %{"places" => places}} ->
        {:ok, Enum.map(places, &format_place/1)}
      {:ok, %{"errorMessage" => error_message}} ->
        {:error, error_message}
      _ ->
        {:error, "Failed to parse POI search response"}
    end
  end

  defp format_place(place) do
    %{
      name: place["name"],
      address: place["address"],
      road_address: place["roadAddress"],
      latitude: place["y"],
      longitude: place["x"],
      distance: place["distance"]
    }
  end
end
