# Mnesiac

[![Build Status](https://travis-ci.org/beardedeagle/mnesiac.svg?branch=master)](https://travis-ci.org/beardedeagle/mnesiac) [![codecov](https://codecov.io/gh/beardedeagle/mnesiac/branch/master/graph/badge.svg)](https://codecov.io/gh/beardedeagle/mnesiac) [![Hex.pm](http://img.shields.io/hexpm/v/mnesiac.svg?style=flat)](https://hex.pm/packages/mnesiac) [![Hex.pm downloads](https://img.shields.io/hexpm/dt/mnesiac.svg?style=flat)](https://hex.pm/packages/mnesiac)

Mnesia auto clustering made easy!

Docs can be found at [https://hexdocs.pm/mnesiac](https://hexdocs.pm/mnesiac).

**_NOTICE:_** Mnesiac, while stable, is still considered pre `1.0`. This means the API can, and may, change at any time. Please ensure you review the docs and changelog prior to updating.

## Installation

Simply add `mnesiac` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mnesiac, "~> 0.4"}
  ]
end
```

Then add `mnesiac` to your supervision tree, passing in the hosts the list of Mnesia stores by type:

- Supported types:
  - ram_copies
  - disc_copies
  - disc_only_copies

- Supported replication types:
  - **_N_** nodes (represented as positive integers)
  - **_N%_** nodes (represented as `.NN` floats)
  - **_SPECIFIC_** nodes (valid node names only)

- Migrations:
  - Only supports MFA tuples
  - Fires only in the presence of `migrations` key being present
  - `rollback_migration/1` will need to be called manually or it could be called from `init_migration` in a custom implementation

- **_EXAMPLE:_** With `libcluster` using the `Cluster.Strategy.Epmd` strategy:

```elixir
  ...

    topology = Application.get_env(:libcluster, :topologies)
    hosts = topology[:myapp][:config][:hosts]
    config = [
      schema: [ # default is :ram_copies, everywhere
        disc_copies: [node3, node4, node6],
        ram_copies: [node10, node11]
      ],
      stores: [
        [ref: Mnesiac.ExampleStore, disc_copies: [node3, node4, node6], ram_copies: [node10, node11], blacklist: [node1, node2]],
        [
          ref: Mnesiac.ExampleStoreTwo,
          disc_copies: [node10, node11],
          ram_copies: [node3, node4, node6],
          migrations: [{Mnesiac.Test.Support.ExampleStore, :some_migration, []}]
        ],
        ...
      ],
      store_load_timeout: 600_000 # default is 600_000, milliseconds
    ]

    children = [
      {Cluster.Supervisor, [topology, [name: MyApp.ClusterSupervisor]]},
      {Mnesiac.Supervisor, [[hosts: hosts, config: config], [name: MyApp.MnesiacSupervisor]]},
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
            hosts: [:"test01@127.0.0.1", :"test02@127.0.0.1"],
            config: [
              schema: [ # default is :ram_copies, everywhere
                disc_copies: [node3, node4, node6],
                ram_copies: [node10, node11]
              ],
              stores: [
                [ref: Mnesiac.ExampleStore, disc_copies: [node3, node4, node6], ram_copies: [node10, node11], blacklist: [node1, node2]],
                [
                  ref: Mnesiac.ExampleStoreTwo,
                  disc_copies: [node10, node11],
                  ram_copies: [node3, node4, node6],
                  migrations: [{Mnesiac.Test.Support.ExampleStore, :some_migration, []}]
                ],
                ...
              ],
              store_load_timeout: 600_000 # default is 600_000, milliseconds
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

All stores *MUST* implement its own `store_options/0`, which returns a keyword list of store options.

There are seven optional callbacks which can be implemented:

- `init_schema/1`, which allows users to implement custom schema initialization logic.
- `copy_schema/1`, which allows users to implement a custom call to copy schema.
- `init_store/1`, which allows users to implement custom store initialization logic.
- `copy_store/1`, which allows users to implement a custom call to copy a store.
- `resolve_conflict/2`, which allows a user to implement logic when it has detected records for a store on both the local and remote nodes it is connecting to. The default implementation is to do nothing.
- `init_migration/1`, which allows users to implement custom migration logic. The default implementation is to do nothing.
- `rollback_migration/1`, which allows users to implement custom migration rollback logic. The default implementation is to do nothing.

**_MINIMAL EXAMPLE:_**:

```elixir
defmodule MyApp.ExampleStore do
  @moduledoc false
  require Record
  use Mnesiac.Store

  Record.defrecord(
    :example,
    __MODULE__,
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

  @impl true
  def store_options,
    do: [
      attributes: example() |> example() |> Keyword.keys(),
      index: [:topic_id],
      ram_copies: [node()]
    ]
end
```

### Clustering

If you are using `libcluster` or another clustering library just ensure that clustering library starts earlier than `mnesiac`. That's all, you don't need to do anything else.

If you are not using `libcluster` or similar clustering library then:

- When a node joins to an erlang/elixir cluster, run the `Mnesiac.init_mnesia/1` function on the *new node*. This will initialize and copy the store contents from the other online nodes.

## Development

Ensure you have the proper language versions installed. To do this, an `asdf` tools file is provided. Run the following:

```shell
git clone https://github.com/beardedeagle/mnesiac.git
git checkout -b MyFeature
asdf install
mix local.hex --force
mix local.rebar --force
mix deps.get --force
mix deps.compile --force
mix compile --force
mix check
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
