defmodule CielStateMachine.Supervisor do
  use Supervisor
  alias CielStateMachine.Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    url = Application.get_env(:ciel_state_machine, :dispatch_engine_service)[:url]
		service = Application.get_env(:ciel_state_machine, :business_logic)[:service]
		rtkOn = Application.get_env(:ciel_state_machine, :rtk)[:on]
    Logger.info("Starting CielStateMachine.Supervisor #{url}", module: __MODULE__)
    Logger.info("Starting Business Logic: #{inspect(service)}", module: __MODULE__)
    Logger.info("Starting RTK #{inspect(rtkOn)}", module: __MODULE__)
    children = [
      CielStateMachine.Producer,
      CielStateMachine.ProcessRegistry,
      CielStateMachine.Database,
      CielStateMachine.ProcessFactory,
      CielStateMachine.Api,
			{CielStateMachine.Store, [service]},
    ]
		case rtkOn do
			:on ->
				new_children = [CielStateMachine.Rtk | children]
				Supervisor.init(new_children, strategy: :one_for_one)
			_ ->
				Supervisor.init(children, strategy: :one_for_one)
		end
  end
end
