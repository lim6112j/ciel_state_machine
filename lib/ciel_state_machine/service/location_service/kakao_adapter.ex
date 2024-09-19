defmodule CielStateMachine.LocationService.KakaoAdapter do
  @base_url "https://dapi.kakao.com/v2/local"

  def reverse_geocode(latitude, longitude) do
    url = "#{@base_url}/geo/coord2address.json?y=#{latitude}&x=#{longitude}"
    headers = [
      {"Authorization", "KakaoAK #{Application.get_env(:ciel_state_machine, :kakao_map_api_key)}"}
    ]

    case Req.get(url, headers: headers) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, parse_reverse_geocode_response(body, latitude, longitude)}
      {:error, %Req.Response{status: status}} ->
        {:error, "Failed to reverse geocode. Status: #{status}"}
      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp parse_reverse_geocode_response(%{"documents" => [first | _]}, latitude, longitude) do
    road_address = first["road_address"]
    address = first["address"]

    %{
      service: "kakao",
      address: get_in(address, ["address_name"]) || "",
      roadAddress: get_in(road_address, ["address_name"]) || "",
      buildingName: get_in(road_address, ["building_name"]) || "",
      postalCode: get_in(road_address, ["zone_no"]) || get_in(address, ["zip_code"]) || "",
      location: %{
        latitude: String.to_float(latitude),
        longitude: String.to_float(longitude)
      },
      region: %{
        region_1depth_name: get_in(address, ["region_1depth_name"]) || get_in(road_address, ["region_1depth_name"]) || "",
        region_2depth_name: get_in(address, ["region_2depth_name"]) || get_in(road_address, ["region_2depth_name"]) || "",
        region_3depth_name: get_in(address, ["region_3depth_name"]) || get_in(road_address, ["region_3depth_name"]) || ""
      }
    }
  end

  defp parse_reverse_geocode_response(_, _, _), do: {:error, "Invalid response format"}

  def poi_search(keyword, latitude, longitude, radius \\ nil) do
    url =
      "#{@base_url}/search/keyword.json?query=#{URI.encode(keyword)}&y=#{latitude}&x=#{longitude}"

    url = if radius, do: "#{url}&radius=#{radius}", else: url

    headers = [
      {"Authorization", "KakaoAK #{Application.get_env(:ciel_state_machine, :kakao_map_api_key)}"}
    ]

    case Req.get(url, headers: headers) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, parse_poi_search_response(body)}

      {:error, %Req.Response{status: status}} ->
        {:error, "Failed to search POI. Status: #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp parse_poi_search_response(%{"documents" => documents, "meta" => meta}) do
    %{
      "resultCode" => "Ok",
      "result" => Enum.map(documents, &format_poi_result/1),
      "meta" => format_meta(meta)
    }
  end

  defp parse_poi_search_response(_), do: {:error, "Invalid response format"}

  defp format_poi_result(doc) do
    %{
      "id" => doc["id"],
      "service" => "kakao",
      "name" => doc["place_name"],
      "address" => doc["address_name"],
      "roadAddress" => doc["road_address_name"],
      # Kakao doesn't provide postal code, leaving it empty
      "postalCode" => "",
      "location" => %{
        "latitude" => String.to_float(doc["y"]),
        "longitude" => String.to_float(doc["x"])
      }
    }
  end

  defp format_meta(meta) do
    %{
      total_count: meta["total_count"],
      pageable_count: meta["pageable_count"],
      is_end: meta["is_end"],
      same_name: meta["same_name"]
    }
  end
end
