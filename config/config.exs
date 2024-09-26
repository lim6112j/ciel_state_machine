import Config

config :logger,
  level: :debug,
  backends: [:console, {LoggerFileBackend, :file_log}]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id]

config :logger, :file_log,
  path: "log/#{Mix.env()}.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id]

config :ciel_state_machine,
  # or "google" or "naver"
  map_service: "kakao",
  naver_map_client_id: System.get_env("NAVER_CLIENT_ID") || "NAVER_CLIENT_ID",
  naver_map_client_secret: System.get_env("NAVER_CLIENT_SECRET") || "NAVER_CLIENT_SECRET",
  google_maps_api_key: System.get_env("GOOGLE_API_KEY") || "GOOGLE_API_KEY",
  kakao_map_api_key: System.get_env("KAKAO_API_KEY") || "KAKAO_API_KEY"

config :ciel_state_machine, :dispatch_engine_service,
  url: System.get_env("DISPATCH_ENGINE_SERVICE_URL") || "http://localhost:8700"

# TODO change token with infra during production
config :ciel_state_machine, CielStateMachine.Persistence.InfluxDB,
  auth: [method: :token, token: System.get_env("INFLUXDB_TOKEN") || "my-super-secret-auth-token"],
  bucket: System.get_env("INFLUXDB_BUCKET") || "locations",
  org: System.get_env("INFLUXDB_ORG") || "myorg",
  host: System.get_env("INFLUXDB_HOST") || "localhost",
  version: :v2

# Import environment specific config
if config_env() in [:dev, :test, :prod] do
  import_config "#{config_env()}.exs"
end
