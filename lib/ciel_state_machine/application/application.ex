defmodule CielStateMachine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application
  alias CielStateMachine.Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting CielStateMachine Application", module: __MODULE__)
    CielStateMachine.Supervisor.start_link([])
  end
end