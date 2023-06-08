# Mnesiac

[![CI](https://github.com/beardedeagle/mnesiac/actions/workflows/ci.yml/badge.svg)](https://github.com/beardedeagle/mnesiac/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/beardedeagle/mnesiac/badge.svg?branch=master)](https://coveralls.io/github/beardedeagle/mnesiac?branch=master) [![Hex.pm](http://img.shields.io/hexpm/v/mnesiac.svg?style=flat)](https://hex.pm/packages/mnesiac) [![Hex.pm downloads](https://img.shields.io/hexpm/dt/mnesiac.svg?style=flat)](https://hex.pm/packages/mnesiac)

Mnesia auto clustering made easy!

Docs can be found at [https://hexdocs.pm/mnesiac](https://hexdocs.pm/mnesiac).

**_NOTICE:_** Mnesiac, while stable, is still considered pre `1.0`. This means the API can, and may, change at any time. Please ensure you review the docs and changelog prior to updating, or pin the version of mnesiac you are using in your `mix.exs` if necessary.

**_NOTICE:_** Mnesiac allows a significant amount of freedom with how it behaves. This allows you to customize Mnesiac to suit your needs. However, this also allows for a fair amount of foot gunning. Please ensure you've done your due diligence when using this library, or Mnesia itself for that matter. It isn't a silver bullet, and it shouldn't be treated as one.

## Installation

Simply add `mnesiac` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mnesiac, "~> 0.3"}
  ]
end
```

Edit your app's config.exs to add the list of Mnesia stores:

```elixir
config :mnesiac,
  stores: [MyApp.ExampleStore, ...],
  schema_type: :disc_copies, # defaults to :ram_copies
  table_load_timeout: 600_000 # milliseconds, default is 600_000
```

Then add `mnesiac` to your supervision tree:

- **_EXAMPLE:_** With `libcluster` using the `Cluster.Strategy.Epmd` strategy:

```elixir
  ...

    topology = Application.get_env(:libcluster, :topologies)
    hosts = topology[:myapp][:config][:hosts]

    children = [
      {Cluster.Supervisor, [topology, [name: MyApp.ClusterSupervisor]]},
      {Mnesiac.Supervisor, [hosts, [name: MyApp.MnesiacSupervisor]]},
      ...
    ]

  ...
```

- **_EXAMPLE:_** Without `libcluster`:

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
      ...
    ]

  ...
```

## Usage

### Table creation

Create a table store, `use Mnesiac.Store`, and add it to your app's config.exs.

All stores **_MUST_** implement its own `store_options/0`, which returns a keyword list of store options.

There are three optional callbacks which can be implemented:

- `init_store/0`, which allows users to implement custom store initialization logic. Triggered by Mnesiac.
- `copy_store/0`, which allows users to implement a custom call to copy a store. Triggered by Mnesiac.
- `resolve_conflict/1`, which allows a user to implement logic when Mnesiac detects a store with records on both the local and remote Mnesia cluster node. Triggered by Mnesiac. Default is to do nothing.

**_MINIMAL EXAMPLE:_**

```elixir
defmodule MyApp.ExampleStore do
  @moduledoc """
  Provides the structure of ExampleStore records for a minimal example of Mnesiac.
  """
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  @doc """
  Record definition for ExampleStore example record.
  """
  defrecord(
    :example,
    __MODULE__,
    id: nil,
    topic_id: nil,
    event: nil
  )

  @typedoc """
  ExampleStore example record field type definitions.
  """
  @type example ::
          record(
            :example,
            id: String.t(),
            topic_id: String.t(),
            event: String.t()
          )

  @impl true
  def store_options,
    do: [
      record_name: __MODULE__,
      attributes: example() |> example() |> Keyword.keys(),
      index: [:topic_id],
      ram_copies: [node()]
    ]
end
```

**_The [mnesia record name](https://www.erlang.org/doc/man/mnesia.html#type-create_option) must match the [record tag](https://hexdocs.pm/elixir/Record.html#defrecord/3) value to ensure copy works correctly when joining cluster_**

### Clustering

If you are using `libcluster` or another clustering library, ensure that the clustering library starts before `mnesiac`. That's all, you don't need to do anything else.

If you are not using `libcluster` or similar clustering libraries then:

- When a node joins to an erlang/elixir cluster, run the `Mnesiac.init_mnesia/1` function on the **_new node_**. This will initialize and copy the store contents from the other online nodes in the Mnesia cluster.

## Development

Ensure you have the proper language versions installed. To do this, an `asdf` tools file has been provided. Run the following:

```shell
git clone https://github.com/beardedeagle/mnesiac.git
git checkout -b MyFeature
asdf install
mix local.hex --force
mix local.rebar --force
mix deps.get --force
mix deps.compile --force
mix compile --force
```

**_NOTICE:_** You can find the `asdf` tool [here][1].

## Testing

Before you run any tests, ensure that you have cleaned up Mnesia:

```shell
mix purge.db
```

Test results and coverage reports are generated by running the following:

```shell
mix coveralls.html --trace --slowest 10 --no-start
```

## Notice

This library was built standing on the shoulders of giants. A big thanks goes out to Mustafa Turan. The original library this was forked from can be found here: <https://github.com/mustafaturan/mnesiam>.

Happy coding!

[1]: https://github.com/asdf-vm/asdf
