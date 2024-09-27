import Config

# ... other configurations ...

config :ciel_state_machine, :dummy_influx, enabled: System.get_env("DUMMY_INFLUX_ENABLED") || true

# ... rest of the file ...
