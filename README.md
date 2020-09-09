# Mnesiac

[![Build Status](https://travis-ci.org/beardedeagle/mnesiac.svg?branch=master)](https://travis-ci.org/beardedeagle/mnesiac) [![codecov](https://codecov.io/gh/beardedeagle/mnesiac/branch/master/graph/badge.svg)](https://codecov.io/gh/beardedeagle/mnesiac) [![Hex.pm](http://img.shields.io/hexpm/v/mnesiac.svg?style=flat)](https://hex.pm/packages/mnesiac) [![Hex.pm downloads](https://img.shields.io/hexpm/dt/mnesiac.svg?style=flat)](https://hex.pm/packages/mnesiac)

Mnesia auto clustering made easy!

Docs can be found at [https://hexdocs.pm/mnesiac](https://hexdocs.pm/mnesiac).

**_NOTICE:_** Mnesiac, while stable, is still considered pre `1.0`. This means the API can, and may, change at any time. Please ensure you review the docs and changelog prior to updating.

**_NOTICE:_** Mnesiac allows a significant amount of freedom with how it behaves. This allows you to customize Mnesiac to suit your needs. However, this also allows for a fair amount of foot gunning. Please ensure you've done your due diligence when using this library, or Mnesia itself for that matter. It isn't a silver bullet, and it shouldn't be treated as one.

## Installation

Simply add `mnesiac` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mnesiac, "~> 0.4"}
  ]
end
```

Then add `mnesiac` to your supervision tree, passing in the cluster and the Mnesiac configuration:

- Supported types:
  - ram_copies.
  - disc_copies.
  - disc_only_copies.

- Supported replication types:
  - **_N_** nodes in Mnesia cluster (represented as positive integers).
  - **_N%_** of nodes in Mnesia cluster (represented as `N.NN` floats, where `1.00` would be 100%).
  - **_SPECIFIC_** nodes in Mnesia cluster (valid node names only).

- Migrations:
  - Only supports MFA tuples.
  - Fires only in the presence of `migrations` key being defined. If present in `schema`, it will be silently ignored.
  - `rollback_migration/1` needs to be called manually or it could be called from `init_migration/1` in a custom implementation.

- **_EXAMPLE:_** With `libcluster` using the `Cluster.Strategy.Epmd` strategy:

```elixir
  ...

    topology = Application.get_env(:libcluster, :topologies)
    cluster = topology[:myapp][:config][:hosts]
    config = [
      schema: [ # default is :ram_copies, everywhere
        disc_copies: [:n3@local, :n4@local, :n6@local],
        ram_copies: [:n10@local, :n11@local]
      ],
      stores: [
        [ # default is :ram_copies, everywhere
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

    children = [
      {Cluster.Supervisor, [topology, [name: MyApp.ClusterSupervisor]]},
      {Mnesiac.Supervisor, [[cluster: cluster, config: config], [name: MyApp.MnesiacSupervisor]]},
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
          [
            cluster: [:n3@local, :n4@local],
            config: [
              schema: [ # default is :ram_copies, everywhere
                disc_copies: [:n3@local, :n4@local, :n6@local],
                ram_copies: [:n10@local, :n11@local]
              ],
              stores: [
                [ # default is :ram_copies, everywhere
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
          ],
          [name: MyApp.MnesiacSupervisor]
        ]
      },
      ...
    ]

  ...
```

## Usage

### Store creation

To create a store, `use Mnesiac.Store`, and ensure it's added to the config for Mnesiac you're passing in.

All stores **_MUST_** implement its own `store_options/0`, which returns a keyword list of store options.

There are nine optional callbacks which can be implemented:

- `init_schema/1`, which allows users to implement custom schema initialization logic. Triggered by Mnesiac.
- `copy_schema/2`, which allows users to implement a custom call to copy schema. Triggered by Mnesiac.
- `init_store/1`, which allows users to implement custom store initialization logic. Triggered by Mnesiac.
- `copy_store/1`, which allows users to implement a custom call to copy a store. Triggered by Mnesiac.
- `init_migration/1`, which allows users to implement custom migration logic. Triggered by Mnesiac. Default is to do nothing.
- `rollback_migration/1`, which allows users to implement custom migration rollback logic. Triggered by user. Default is to do nothing.
- `refresh_cluster/1`, which allows users to implement custom logic to refresh Mnesia cluster. Triggered by user. Default is to do nothing.
- `backup/1`, which allows users to implement custom logic to back up Mnesia stores. Triggered by user. Default is to do nothing.
- `resolve_conflict/2`, which allows a user to implement logic when Mnesiac detects a store with records on both the local and remote Mnesia cluster node. Triggered by Mnesiac. Default is to do nothing.

**_MINIMAL EXAMPLE:_**:

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
  Record.defrecord(
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

## Linting and static analysis

Mnesiac provides a single command for linting and static analysis:

```shell
mix check
```

## Testing

Before you run any tests, ensure that you have cleaned up Mnesia:

```shell
mix db.purge
```

Test results and coverage reports are generated by running the following:

```shell
mix coveralls.html --trace --slowest 10 --no-start
```

## Notice

This library was built standing on the shoulders of giants. A big thanks goes out to Mustafa Turan. The original library this was forked from can be found here: <https://github.com/mustafaturan/mnesiam>.

Happy coding!

[1]: https://github.com/asdf-vm/asdf
