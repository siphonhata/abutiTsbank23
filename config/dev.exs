import Config

# Configure your database
config :tsbank, Tsbank.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "tsbank_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10


config :tsbank, TsbankWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4090],
  check_origin: false,
  code_reloader: true,
  debug_errors: false,
  secret_key_base: "Zq+9CFnTXG08sK1TmW97gly4Ytd/ycuF9CPJwKxyXquX10qgGL6L4Yfm7UEQ3BdH",
  watchers: []

config :tsbank, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
