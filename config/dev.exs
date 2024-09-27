import Config

# Override the default URL for development if needed
# config :your_app_name, :routing_service,
#   url: "http://dev-routing-service:8700"

# business logic
config :ciel_state_machine, :business_logic, service: :default

# RTK signal on/off
config :ciel_state_machine, :rtk, on: :off

# Dummy data generator configuration
config :ciel_state_machine, :dummy_influx, enabled: System.get_env("DUMMY_INFLUX_ENABLED") || true
