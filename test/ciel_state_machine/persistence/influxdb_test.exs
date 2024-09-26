defmodule CielStateMachine.Persistence.InfluxDBTest do
  use ExUnit.Case
  alias CielStateMachine.Persistence.InfluxDB
  import Mock

#  describe "query_latest_locations/0" do
#    test "successfully queries and parses latest locations" do
#      mock_query_result = {:ok, %{results: [%{tables: [
#        %{
#          columns: [%{name: "device_id"}, %{name: "latitude"}, %{name: "_time"}],
#          data: [["device1", 37.5665, "2023-09-26T12:00:00Z"]]
#        }
#      ]}]}}
#
#      with_mock InfluxDB, [query: fn(_) -> mock_query_result end] do
#        assert {:ok, [%{"device_id" => "device1", "latitude" => 37.5665, "_time" => 1695729600000}]} = InfluxDB.query_latest_locations()
#      end
#    end
#
#    test "returns error on query failure" do
#      with_mock InfluxDB, [query: fn(_) -> {:error, "Connection failed"} end] do
#        assert {:error, "Query failed: \"Connection failed\""} = InfluxDB.query_latest_locations()
#      end
#    end
#  end
#
#  describe "health_check/0" do
#    test "returns ok when InfluxDB is healthy" do
#      with_mock InfluxDB, [query: fn(_) -> [%{}] end] do
#        assert {:ok, "InfluxDB connection is healthy"} = InfluxDB.health_check()
#      end
#    end
#
#    test "returns error when InfluxDB health check fails" do
#      with_mock InfluxDB, [query: fn(_) -> {:error, "Connection timeout"} end] do
#        assert {:error, "InfluxDB health check failed: \"Connection timeout\""} = InfluxDB.health_check()
#      end
#    end
#  end
#
#  describe "check_config/0" do
#    test "returns configuration string" do
#      result = InfluxDB.check_config()
#      assert is_binary(result)
#      assert String.contains?(result, "InfluxDB Configuration:")
#      assert String.contains?(result, "Host:")
#      assert String.contains?(result, "Port:")
#    end
#  end
#
#  describe "list_buckets/0" do
#    test "successfully lists buckets" do
#      mock_query_result = {:ok, [%{"name" => "bucket1"}, %{"name" => "bucket2"}]}
#
#      with_mock InfluxDB, [query: fn(_) -> mock_query_result end] do
#        assert {:ok, [%{"name" => "bucket1"}, %{"name" => "bucket2"}]} = InfluxDB.list_buckets()
#      end
#    end
#
#    test "returns error when listing buckets fails" do
#      with_mock InfluxDB, [query: fn(_) -> {:error, "Permission denied"} end] do
#        assert {:error, "Failed to list buckets: \"Permission denied\""} = InfluxDB.list_buckets()
#      end
#    end
#  end
#
#  describe "test_write/0" do
#    test "successfully writes test data" do
#      with_mock InfluxDB, [write: fn(_) -> :ok end] do
#        assert {:ok, "Test write successful"} = InfluxDB.test_write()
#      end
#    end
#
#    test "returns error when test write fails" do
#      with_mock InfluxDB, [write: fn(_) -> {:error, "Write failed"} end] do
#        assert {:error, "Test write failed: \"Write failed\""} = InfluxDB.test_write()
#      end
#    end
#  end
#
#  describe "test_query/0" do
#    test "successfully queries test data" do
#      mock_query_result = [
#        %{"_field" => "latitude", "_value" => 37.5665, "_time" => "2023-09-26T12:00:00Z", "deviceId" => "supply_id"},
#        %{"_field" => "longitude", "_value" => 126.9780, "_time" => "2023-09-26T12:00:00Z", "deviceId" => "supply_id"}
#      ]
#
#      with_mock InfluxDB, [query: fn(_) -> mock_query_result end] do
#        assert {:ok, %{latitude: 37.5665, longitude: 126.9780, timestamp: "2023-09-26T12:00:00Z", device_id: "supply_id"}} = InfluxDB.test_query()
#      end
#    end
#
#    test "returns error when test query fails" do
#      with_mock InfluxDB, [query: fn(_) -> {:error, "Query failed"} end] do
#        assert {:error, "Query failed: \"Query failed\""} = InfluxDB.test_query()
#      end
#    end
#  end
end
