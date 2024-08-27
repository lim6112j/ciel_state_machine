import Config

config :logger,
       backends: [:console, {LoggerFileBackend, :file_log}]

config :logger, :console,
       format: "$time $metadata[$level] $message\n",
       metadata: [:request_id, :user_id]

config :logger, :file_log,
       path: "log/#{Mix.env()}.log",
       level: :info,
       format: "$time $metadata[$level] $message\n",
       metadata: [:request_id, :user_id]


config :ciel_state_machine, :dispatch_engine_service,
       url: System.get_env("DISPATCH_ENGINE_SERVICE_URL") || "http://localhost:8700"

# Import environment specific config
if config_env() in [:dev, :test, :prod] do
  import_config "#{config_env()}.exs"
end
