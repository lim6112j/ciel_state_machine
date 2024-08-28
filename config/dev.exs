import Config

# Override the default URL for development if needed
# config :your_app_name, :routing_service,
#   url: "http://dev-routing-service:8700"

config :ciel_state_machine, :business_logic, service: :test

config :ciel_state_machine, :rtk, on: :off
