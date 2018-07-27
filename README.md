# Mnesiac

mnesia autoclustering made easy!

Docs can be found at [https://hexdocs.pm/mnesiac](https://hexdocs.pm/mnesiac).

## Installation

Simply add `mnesiac` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mnesiac, "~> 0.1.0"}
  ]
end
```

Edit your app's config.exs to add the list of mnesia stores:

```elixir
config :mnesiac,
  stores: [Mnesiac.ExampleStore, ...],
  schema_type: :disc_copies, # defaults to :ram_copies
  table_load_timeout: 600_000 # milliseconds
```

And then add `mnesiac` to your supervision tree:

With `libcluster`:

```elixir
  ...

    topology = Application.get_env(:libcluster, :topologies)
    hosts = topology[:myapp][:config][:hosts]

    children = [
      {Cluster.Supervisor, [topology, [name: MyApp.ClusterSupervisor]]},
      {Mnesiac.Supervisor, [hosts, [name: MyApp.MnesiacSupervisor]]},
      ..other children..
    ]

  ...
```

Without `libcluster`:

```elixir
  ...

    children = [
      {
        Mnesiac.Supervisor,
        [
          [:"test01@127.0.0.1", :"test02@127.0.0.1"],
          [name: MyApp.MnesiacSupervisor]
        ]
      },
      ..other children..
    ]

  ...
```

## Usage

### Table creation

Create a table store and add it to your app's config.exs. Note: All stores *MUST* implement its own `init_store/0` to create a table and `copy_store/0` to copy a table:

```elixir
defmodule MyApp.ExampleStore do
  @moduledoc """
  Example store implementation
  """
  require Record

  Record.defrecord(
    :example,
    ExampleStore,
    id: nil,
    topic_id: nil,
    event: nil
  )

  @type example ::
          record(
            :example,
            id: String.t(),
            topic_id: String.t(),
            event: String.t()
          )

  @doc """
  Mnesiac will call this method to initialize the table
  """
  def init_store do
    :mnesia.create_table(
      ExampleStore,
      attributes: example() |> example() |> Keyword.keys(),
      index: [:topic_id],
      disc_copies: [Node.self()]
    )
  end

  @doc """
  Mnesiac will call this method to copy the table
  """
  def copy_store do
    :mnesia.add_table_copy(ExampleStore, Node.self(), :disc_copies)
  end

  ...
end
```

### Clustering

If you are using `libcluster` or another clustering library just ensure that clustering library starts earlier than `mneasiac`. That's all, you do not need to do rest.

If you are not using `libcluster` or similar clustering library then:

- When a node joins to an erlang/elixir cluster, run the `Mnesiac.init_mnesia()` function on the *new node*. This will initialize and copy table contents from the other online nodes.

Enjoy!
