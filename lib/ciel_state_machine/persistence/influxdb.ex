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
        {:ok, parse_query_result(tables)}
      [] ->
        {:ok, []} # Return an empty list as a successful result
      {:error, reason} ->
        {:error, "Query failed: #{inspect(reason)}"}
    end
  end

  defp parse_query_result(data) do
    data
    |> List.flatten()
    |> Enum.group_by(fn item -> item["deviceId"] end)
    |> Enum.map(fn {device_id, items} ->
      latest_item = Enum.max_by(items, fn item -> item["_time"] end)
      fields = Enum.reduce(items, %{}, fn item, acc ->
        Map.put(acc, item["_field"], item["_value"])
      end)
      Map.merge(fields, %{
        device_id: device_id,
        timestamp: format_timestamp(latest_item["_time"])
      })
    end)
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

  def test_query(device_id \\ "supply_id2") do
    flux_query = """
    from(bucket: "#{config()[:bucket]}")
      |> range(start: -1h)
      |> filter(fn: (r) => r._measurement == "locReports")
      |> filter(fn: (r) => r.deviceId == "#{device_id}")
      |> last()
    """
    result = __MODULE__.query(flux_query)
    Logger.info(inspect(result))
    case result do
      data when is_list(data) ->
        # Logger.info("Query result length: #{length(data)}")
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

  def fetch_locations_for_devices(device_ids, time_range \\ "-1h") do
    device_ids_string = Enum.join(device_ids, "|")
    flux_query = """
    from(bucket: "#{config()[:bucket]}")
      |> range(start: #{time_range})
      |> filter(fn: (r) => r._measurement == "locReports")
      |> filter(fn: (r) => r.deviceId =~ /(#{device_ids_string})/)
    """

    Logger.info("Executing query: #{flux_query}")

    case __MODULE__.query(flux_query) do
      data when is_list(data) ->
        Logger.info("Raw query result: #{inspect(data, pretty: true)}")
        parsed_data = parse_query_result(data)
        Logger.info("Parsed data: #{inspect(parsed_data, pretty: true)}")
        {:ok, parsed_data}

      {:error, reason} ->
        Logger.error("Failed to fetch locations for devices. Reason: #{inspect(reason)}")
        {:error, "Query failed: #{inspect(reason)}"}

      unexpected ->
        Logger.warn("Unexpected response format: #{inspect(unexpected)}")
        {:error, "Unexpected response format"}
    end
  end

  defp parse_query_result(data) do
    data
    |> List.flatten()
    |> Enum.group_by(fn item -> item["deviceId"] end)
    |> Enum.map(fn {device_id, items} ->
      latest_item = Enum.max_by(items, fn item -> item["_time"] end)
      fields = Enum.reduce(items, %{}, fn item, acc ->
        Map.put(acc, item["_field"], item["_value"])
      end)
      Map.merge(fields, %{
        device_id: device_id,
        timestamp: format_timestamp(latest_item["_time"])
      })
    end)
  end

  defp format_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, datetime, _offset} -> DateTime.to_unix(datetime, :millisecond)
      _ -> timestamp
    end
  end

  defp format_timestamp(timestamp), do: timestamp

  def write_location(device_id, state) do
    now = DateTime.utc_now()
    data = %MobbleMODLocation{
      fields: %MobbleMODLocation.Fields{
        latitude: state.latitude / 1,
        longitude: state.longitude / 1,
        altitude: state.altitude / 1,
        height: state.height / 1,  # Add height field
        speed: state.speed / 1,
        angle: state.angle / 1,
        in_path: state.in_path,
        get_time: DateTime.to_unix(now, :nanosecond)
      },
      tags: %MobbleMODLocation.Tags{deviceId: device_id},
      timestamp: DateTime.to_unix(now, :nanosecond)
    }

    case __MODULE__.write(data) do
      :ok ->
        Logger.info("Location data written for device #{device_id}")
        :ok
      {:error, reason} ->
        Logger.error("Failed to write location data for device #{device_id}. Reason: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
