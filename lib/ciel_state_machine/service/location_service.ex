defmodule CielStateMachine.LocationService do
  alias CielStateMachine.LocationService.{NaverAdapter, GoogleAdapter, KakaoAdapter}

  @adapters %{
    "naver" => NaverAdapter,
    "google" => GoogleAdapter,
    "kakao" => KakaoAdapter
  }

  def reverse_geocode(latitude, longitude) do
    adapter = get_adapter()

    case adapter.reverse_geocode(latitude, longitude) do
      {:ok, result} -> {:ok, format_reverse_geocode_response(result)}
      {:error, reason} -> {:error, reason}
    end
  end

  def poi_search(keyword, latitude, longitude, radius \\ nil) do
    adapter = get_adapter()
    IO.puts("Using adapter: #{inspect(adapter)}")
    IO.puts("Searching for: #{keyword} at (#{latitude}, #{longitude}) with radius #{radius}")

    case adapter.poi_search(keyword, latitude, longitude, radius) do
      {:ok, %{"resultCode" => "Ok", "result" => results, "meta" => meta}} ->
        {:ok,
         %{
           "resultCode" => "Ok",
           "result" => results,
           "meta" => meta
         }}

      {:ok, response} when is_list(response) ->
        # Handle responses from adapters that return a list directly
        {:ok, format_poi_search_response(response)}

      {:error, reason} ->
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
          "roadAddress" => response.roadAddress,
          "buildingName" => response.buildingName,
          "postalCode" => response.postalCode,
          "location" => %{
            "latitude" => response.location.latitude,
            "longitude" => response.location.longitude
          }
        }
      ]
    }
  end

  defp format_poi_search_response(response) do
    %{
      "resultCode" => "Ok",
      "result" =>
        Enum.map(response, fn poi ->
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
