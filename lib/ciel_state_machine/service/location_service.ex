defmodule CielStateMachine.LocationService do
  alias CielStateMachine.LocationService.{NaverAdapter, GoogleAdapter, KakaoAdapter}

  @adapters %{
    "naver" => NaverAdapter,
    "google" => GoogleAdapter,
    "kakao" => KakaoAdapter
  }

  def reverse_geocode(latitude, longitude) do
    adapter = get_adapter()
    adapter.reverse_geocode(latitude, longitude)
    |> format_reverse_geocode_response()
  end

  def poi_search(keyword, latitude, longitude, radius \\ nil) do
    adapter = get_adapter()
    IO.puts("Using adapter: #{inspect(adapter)}")
    IO.puts("Searching for: #{keyword} at (#{latitude}, #{longitude}) with radius #{radius}")

    case adapter.poi_search(keyword, latitude, longitude, radius) do
      {:ok, results} ->
        IO.puts("Search successful. Found #{length(results)} results.")
        {:ok, format_poi_search_response(results)}
      {:error, reason} ->
        IO.puts("Search failed. Reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_adapter do
    service = Application.get_env(:ciel_state_machine, :map_service)
    Map.get(@adapters, service) || raise "Unsupported map service: #{service}"
  end

  defp format_reverse_geocode_response(response) do
    %{
      "resultCode" => "Ok",
      "result" => [
        %{
          "service" => response.service,
          "address" => response.address,
          "roadAddress" => response.road_address,
          "buildingName" => response.building_name,
          "postalCode" => response.postal_code,
          "location" => %{
            "latitude" => response.latitude,
            "longitude" => response.longitude
          }
        }
      ]
    }
  end

  defp format_poi_search_response(response) do
    %{
      "resultCode" => "Ok",
      "result" => Enum.map(response, fn poi ->
        %{
          "id" => poi.id,
          "service" => poi.service,
          "name" => poi.name,
          "address" => poi.address,
          "roadAddress" => poi.road_address,
          "postalCode" => poi.postal_code,
          "location" => %{
            "latitude" => poi.latitude,
            "longitude" => poi.longitude
          }
        }
      end)
    }
  end
end