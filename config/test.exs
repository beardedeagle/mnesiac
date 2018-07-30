use Mix.Config

config :mnesiac,
  stores: [Mnesiac.ExampleStore],
  schema_type: :disc_copies,
  table_load_timeout: 600_000
