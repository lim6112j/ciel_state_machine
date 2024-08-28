defmodule CielStateMachine.Supervisor do
  use Supervisor
  alias CielStateMachine.Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    url = Application.get_env(:ciel_state_machine, :dispatch_engine_service)[:url]
    Logger.info("Starting CielStateMachine.Supervisor #{url}", module: __MODULE__)
    children = [
      CielStateMachine.Producer,
      CielStateMachine.ProcessRegistry,
      CielStateMachine.Database,
      CielStateMachine.ProcessFactory,
      CielStateMachine.Api,
      CielStateMachine.Store,
			CielStateMachine.Rtk
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
