defmodule CielStateMachine.LocationService.KakaoAdapter do
  @base_url "https://dapi.kakao.com/v2/local"

  def reverse_geocode(latitude, longitude) do
    url = "#{@base_url}/geo/coord2address.json?x=#{longitude}&y=#{latitude}"
    headers = [{"Authorization", "KakaoAK #{Application.get_env(:ciel_state_machine, :kakao_map_api_key)}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_reverse_geocode_response(body)
      _ ->
        {:error, "Failed to reverse geocode"}
    end
  end

  def poi_search(keyword, latitude, longitude, radius) do
    url = "#{@base_url}/search/keyword.json?query=#{URI.encode(keyword)}&x=#{longitude}&y=#{latitude}"
    url = if radius, do: "#{url}&radius=#{radius}", else: url
    headers = [{"Authorization", "KakaoAK #{Application.get_env(:ciel_state_machine, :kakao_map_api_key)}"}]

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: body}} ->
        parse_poi_search_response(body)
      _ ->
        {:error, "Failed to search POI"}
    end
  end

  defp parse_reverse_geocode_response(body) do
    # Implement parsing logic for Kakao's response
    # Return a map with keys matching the format_reverse_geocode_response function
  end

  defp parse_poi_search_response(body) do
    # Implement parsing logic for Kakao's response
    # Return a list of maps with keys matching the format_poi_search_response function
  end
end