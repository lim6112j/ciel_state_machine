defmodule CielStateMachine.Persistence.DummyDataGenerator do
  use GenServer
  require Logger
  alias CielStateMachine.Persistence.InfluxDB
  alias CielStateMachine.Persistence.InfluxDB.MobbleMODLocation

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def add_devices(devices, interval \\ 1000) do
    GenServer.call(__MODULE__, {:add_devices, devices, interval})
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  @impl true
  def init(_opts) do
    # Add initial devices
    initial_devices = ["device1", "device2", "device3"]
    initial_state = %{devices: %{}, timer: nil}

    {:reply, :ok, state} = handle_call({:add_devices, initial_devices, 1000}, nil, initial_state)

    {:ok, state}
  end

  @impl true
  def handle_call({:add_devices, devices, interval}, _from, state) do
    new_devices = Enum.map(devices, fn id -> {id, initial_state()} end) |> Map.new()
    updated_devices = Map.merge(state.devices, new_devices)

    if state.timer, do: Process.cancel_timer(state.timer)
    timer = Process.send_after(self(), :generate_data, interval)

    {:reply, :ok, %{state | devices: updated_devices, timer: timer}}
  end

  @impl true
  def handle_info(:generate_data, %{devices: devices, timer: old_timer} = state) do
    if old_timer, do: Process.cancel_timer(old_timer)

    new_devices = Enum.map(devices, fn {id, device_state} ->
      new_state = update_state(device_state)
      write_dummy_data(id, new_state)
      {id, new_state}
    end) |> Map.new()

    timer = Process.send_after(self(), :generate_data, 1000)
    {:noreply, %{state | devices: new_devices, timer: timer}}
  end

  # Helper functions

  defp initial_state do
    %{
      latitude: (:rand.uniform() * 180 - 90) / 1,
      longitude: (:rand.uniform() * 360 - 180) / 1,
      altitude: :rand.uniform() * 1000,
      height: :rand.uniform() * 10,
      speed: :rand.uniform() * 100,
      angle: :rand.uniform() * 360,
      in_path: Enum.random([0, 1])
    }
  end

  defp update_state(state) do
    %{
      latitude: state.latitude + (:rand.normal() * 0.001),
      longitude: state.longitude + (:rand.normal() * 0.001),
      altitude: max(0, state.altitude + (:rand.normal() * 10)),
      height: max(0, state.height + (:rand.normal() * 0.1)),
      speed: max(0, state.speed + (:rand.normal() * 5)),
      angle: Float.round(normalize_angle(state.angle + (:rand.normal() * 10)), 2),
      in_path: Enum.random([0, 1])
    }
  end

  defp normalize_angle(angle) do
    cond do
      angle < 0 -> normalize_angle(angle + 360)
      angle >= 360 -> normalize_angle(angle - 360)
      true -> angle
    end
  end

  defp write_dummy_data(device_id, state) do
    case InfluxDB.write_location(device_id, state) do
      :ok ->
        Logger.info("Dummy data written for device #{device_id}")
      {:error, reason} ->
        Logger.error("Failed to write dummy data for device #{device_id}. Reason: #{inspect(reason)}")
    end
  end
end
