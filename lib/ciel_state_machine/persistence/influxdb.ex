defmodule CielStateMachine.Persistence.InfluxDB do
  #
  use Instream.Connection, otp_app: :ciel_state_machine
  require Logger

  # TODO need to validate to have longitude, lattitude, timestamp and deviceId
  defmodule MobbleMODLocation do
    use Instream.Series

    series do
      measurement("locReports")

      # supply id
      tag(:deviceId)

      field(:latitude)
      field(:longitude)
      field(:altitude, default: 0)
      field(:height, default: 0)
      field(:speed, default: 0)
      field(:angle, default: 0)
      field(:in_path)
      field(:get_time)
    end
  end

  def query_latest_locations do
    flux_query = """
    from(bucket: "#{config()[:bucket]}")
      |> range(start: -1h)
      |> filter(fn: (r) => r._measurement == "location")
      |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
      |> group(columns: ["device_id"])
      |> last()
    """

    case __MODULE__.query(flux_query) do
      {:ok, %{results: [%{tables: tables}]}} ->
        parse_query_result(tables)

      {:error, reason} ->
        {:error, "Query failed: #{inspect(reason)}"}
    end
  end

  defp parse_query_result(tables) do
    Enum.map(tables, fn %{columns: columns, data: data} ->
      column_names = Enum.map(columns, & &1.name)

      Enum.map(data, fn row ->
        Enum.zip(column_names, row)
        |> Enum.into(%{})
        |> Map.update("_time", nil, &format_timestamp/1)
      end)
    end)
    |> List.flatten()
  end

  defp format_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, datetime, _offset} -> DateTime.to_unix(datetime, :millisecond)
      _ -> timestamp
    end
  end

  defp format_timestamp(timestamp), do: timestamp

  def health_check do
    flux_query = "from(bucket:\"#{config()[:bucket]}\") |> range(start: -24h) |> limit(n:1)"

    case __MODULE__.query(flux_query) do
      data when is_list(data) ->
        Logger.info("Health check query successful. Results: #{inspect(data)}")
        {:ok, "InfluxDB connection is healthy"}

      {:error, reason} ->
        Logger.error("Health check failed. Reason: #{inspect(reason)}")
        {:error, "InfluxDB health check failed: #{inspect(reason)}"}
      unexpected ->
        Logger.warn("Unexpected response format: #{inspect(unexpected)}")
        {:error, "Unexpected response format"}
    end
  end


  def check_config do
    config = config()

    """
    InfluxDB Configuration:
    Host: #{config[:host]}
    Port: #{config[:port]}
    Scheme: #{config[:scheme]}
    Token: #{String.slice(config[:token] || "", 0..10)}...
    Org: #{config[:org]}
    Bucket: #{config[:bucket]}
    Version: #{config[:version]}
    """
  end

  @spec list_buckets() :: {:error, <<_::64, _::_*8>>} | {:ok, any()}
  def list_buckets do
    flux_query = "buckets() |> limit(n: 100)"

    case __MODULE__.query(flux_query) do
      {:ok, rsp} ->
        Logger.info("rsp #{rsp}")
        {:ok, rsp}

      {:error, reason} ->
        Logger.error("Failed to list buckets. Reason: #{inspect(reason)}")
        {:error, "Failed to list buckets: #{inspect(reason)}"}
    end
  end

  # 밑에는 참고용 테스트 쓰기 읽기 함수 들입니다.
  def test_write do
    now = DateTime.utc_now()

    data = %MobbleMODLocation{
      fields: %MobbleMODLocation.Fields{
        latitude: 37.5665,
        longitude: 126.9780,
        altitude: 38.5,
        height: 2.0,
        speed: 5.2,
        angle: 45.0,
        in_path: 1,
        get_time: DateTime.to_unix(now, :nanosecond)
      },
      tags: %MobbleMODLocation.Tags{deviceId: "supply_id"},
      timestamp: DateTime.to_unix(now, :nanosecond)
    }

    case __MODULE__.write(data) do
      :ok ->
        Logger.info("Test write successful")
        {:ok, "Test write successful"}

      {:error, reason} ->
        Logger.error("Test write failed. Reason: #{inspect(reason)}")
        {:error, "Test write failed: #{inspect(reason)}"}
    end
  end

  def test_query() do
    device_id = "supply_id"
    flux_query = """
    from(bucket: "#{config()[:bucket]}")
      |> range(start: -1h)
      |> filter(fn: (r) => r._measurement == "locReports")
      |> filter(fn: (r) => r.deviceId == "#{device_id}")
      |> last()
    """

    case __MODULE__.query(flux_query) do
      data when is_list(data) ->
        {:ok, parse_location_data(List.flatten(data))}

        {:error, reason} ->
          Logger.error("Query failed for device ID #{device_id}. Reason: #{inspect(reason)}")
          {:error, "Query failed: #{inspect(reason)}"}

        unexpected ->
          Logger.warn("Unexpected response format: #{inspect(unexpected)}", unexpected: unexpected)
          {:error, "Unexpected response format"}

    end
  end

  defp parse_location_data(data) do
    Enum.reduce(data, %{}, fn item, acc ->
      %{"_field" => field, "_value" => value, "_time" => time, "deviceId" => device_id} = item
      Map.merge(acc, %{
        String.to_atom(field) => value,
        :timestamp => time,
        :device_id => device_id
      })
    end)
  end
end
