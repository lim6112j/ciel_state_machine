defmodule CielStateMachine.InfluxSyncServer do
  use GenServer
  alias CielStateMachine.Persistence.InfluxDB
  alias CielStateMachine.Store
  require Logger

  @update_interval 1000 # 1 second
  @initial_delay 3000 # 3 seconds

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing InfluxSyncServer")
    Process.send_after(self(), :start_operations, @initial_delay)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:start_operations, state) do
    Logger.info("Starting InfluxSyncServer operations")
    {:noreply, state, {:continue, :initialize}}
  end

  @impl true
  def handle_info(:update_locations, state) do
    Logger.debug("Updating car locations")
    case InfluxDB.query_latest_locations() do
      {:ok, []} ->
        Logger.debug("No location updates found")
      {:ok, locations} ->
        updates = Enum.map(locations, fn location ->
          {location.device_id, %{lng: location.longitude, lat: location.latitude}}
        end)
        Store.dispatch(%{type: "UPDATE_CAR_LOCATION"}, updates)
      {:error, reason} ->
        Logger.error("Failed to fetch location updates: #{inspect(reason)}")
    end
    schedule_update()
    {:noreply, state}
  end

  @impl true
  def handle_continue(:initialize, state) do
    Logger.info("Fetching initial data from InfluxDB")
    case InfluxDB.query_latest_locations() do
      {:ok, []} ->
        Logger.info("No initial data found in InfluxDB")
        schedule_update()
        {:noreply, state}
      {:ok, locations} ->
        Enum.each(locations, fn location ->
          Store.dispatch(%{type: "ADD_VEHICLE"}, location.device_id)
        end)
        schedule_update()
        {:noreply, state}
      {:error, reason} ->
        Logger.error("Failed to fetch initial data: #{inspect(reason)}")
        {:stop, :initialization_failed, state}
    end
  end

  defp schedule_update do
    Process.send_after(self(), :update_locations, @update_interval)
  end
end
