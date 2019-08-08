defmodule Mnesiac.Supervisor do
  @moduledoc """
  Mnesiac supervisor.
  """
  use Supervisor

  @doc """
  Entry point for Mnesiac when used in a supervision tree.
  ```elixir
  config = [
    schema: [
      disc_copies: [:n3@local, :n4@local, :n6@local],
      ram_copies: [:n10@local, :n11@local]
    ],
    stores: [
      [
        ref: Mnesiac.ExampleStore,
        disc_copies: [:n3@local, :n4@local, :n6@local],
        ram_copies: [:n10@local, :n11@local],
        blacklist: [:n10@local, :n11@local]
      ],
      [
        ref: Mnesiac.ExampleStoreTwo,
        disc_copies: [:n10@local, :n11@local],
        ram_copies: [:n3@local, :n4@local, :n6@local],
        migrations: [{Mnesiac.Test.Support.ExampleStore, :some_migration, []}]
      ]
    ],
    store_load_timeout: 600_000
  ]
  Mnesiac.Supervisor.start_link([cluster: [node()], config: config])
  ```
  """
  @spec start_link(init_arg :: [Mnesiac.init_arg() | keyword()] | Mnesiac.init_arg()) ::
          :ignore | {:error, term()} | {:ok, pid()}
  def start_link([[cluster: _cluster, config: _config], opts] = init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, opts)
  end

  def start_link([cluster: _cluster, config: _config] = init_arg), do: start_link([init_arg, []])

  @impl true
  def init([config, opts]) do
    Mnesiac.init_mnesia(config)
    opts = Keyword.put(opts, :strategy, :one_for_one)
    Supervisor.init([], opts)
  end
end
