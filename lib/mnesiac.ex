defmodule Mnesiac do
  @moduledoc """
  Mnesiac Manager.
  """
  require Logger

  @typedoc """
  Default arguments expected to be passed in to Mnesiac. `override` is optional.
  """
  @type arg ::
          {:cluster, [node()]}
          | {:config, config}
          | {:override, (config -> {:ok, struct()} | {:error, term()}) | nil}

  @typedoc """
  Default implementation of arguments expected to be passed in to Mnesiac.
  """
  @type init_arg :: [arg]

  @typedoc """
  Default configuration expected to be passed in to Mnesiac. `store_load_timeout` is optional.
  """
  @type config ::
          {:schema, Mnesiac.Store.config()}
          | {:stores, [Mnesiac.Store.config(), ...]}
          | {:store_load_timeout, integer()}

  @typedoc """
  Defines the configuration for mnesiac.
  ## Example
  ```elixir
  %Mnesiac{
    schema: %Mnesiac.Store{
      blacklist: [],
      disc_copies: [],
      disc_only_copies: [],
      migrations: [],
      ram_copies: [1.0],
      ref: :schema
    },
    store_load_timeout: 600000,
    stores: [
      %Mnesiac.Store{
        blacklist: [:n10@local, :n11@local],
        disc_copies: [:n3@local, :n4@local, :n6@local],
        disc_only_copies: [],
        migrations: [],
        ram_copies: [:n10@local, :n11@local],
        ref: Mnesiac.ExampleStore
      },
      %Mnesiac.Store{
        blacklist: [],
        disc_copies: [:n10@local, :n11@local],
        disc_only_copies: [],
        migrations: [{Mnesiac.Test.Support.ExampleStore, :some_migration, []}],
        ram_copies: [:n3@local, :n4@local, :n6@local],
        ref: Mnesiac.ExampleStoreTwo
      }
    ]
  }
  ```
  """
  @type t :: %__MODULE__{
          schema: %Mnesiac.Store{},
          stores: [%Mnesiac.Store{}, ...],
          store_load_timeout: integer()
        }

  @enforce_keys [:schema, :stores]
  defstruct schema: nil,
            stores: [],
            store_load_timeout: 600_000

  @doc """
  Initialize Mnesia. Filters out cluster nodes not explicitly passed in.
  ## Example
  ```elixir
  iex(1)> config = [
    schema: [
      disc_copies: [node3, node4, node6],
      ram_copies: [node10, node11]
    ],
    stores: [
      [ref: Mnesiac.ExampleStore, disc_copies: [node3, node4, node6], ram_copies: [node10, node11], blacklist: [node1, node2]]
    ],
    store_load_timeout: 600_000
  ]
  iex(2)> Mnesiac.init_mnesia([cluster: [node()], config: config])
  :ok
  ```
  """
  @spec init_mnesia(Mnesiac.init_arg()) :: :ok | {:error, term()}
  def init_mnesia(cluster: cluster, config: config, override: override) do
    case filter_cluster(cluster) do
      [head | _tail] -> join_cluster(config, override, head)
      [] -> start(config, override)
    end
  end

  def init_mnesia(cluster: cluster, config: config), do: init_mnesia(cluster: cluster, config: config, override: nil)

  @doc """
  Validate configuration being passed in to Mnesiac will build to a proper Mneisac configuration struct.
  ```elixir
  iex(1)> Mnesiac.validate_config(config)
  {:ok,
    %Mnesiac{
      schema: %Mnesiac.Store{
        blacklist: [],
        disc_copies: [:n3@local, :n4@local, :n6@local],
        disc_only_copies: [],
        migrations: [],
        ram_copies: [:n10@local, :n11@local],
        ref: :schema
      },
      store_load_timeout: 600000,
      stores: [
        %Mnesiac.Store{
          blacklist: [:n10@local, :n11@local],
          disc_copies: [:n3@local, :n4@local, :n6@local],
          disc_only_copies: [],
          migrations: [],
          ram_copies: [:n10@local, :n11@local],
          ref: Mnesiac.ExampleStore
        },
        %Mnesiac.Store{
          blacklist: [],
          disc_copies: [:n10@local, :n11@local],
          disc_only_copies: [],
          migrations: [{Mnesiac.Test.Support.ExampleStore, :some_migration, []}],
          ram_copies: [:n3@local, :n4@local, :n6@local],
          ref: Mnesiac.ExampleStoreTwo
        }
      ]
    }}
  ```
  """
  @spec validate_config(
          config :: config(),
          override :: (config() -> {:ok, struct()} | {:error, term()}) | nil
        ) :: {:ok, struct()} | {:error, term()}
  def validate_config(config, override \\ nil), do: build_struct(config, override)

  @doc """
  Get the cluster status.
  ## Example
  ```elixir
  iex(1)> Mnesiac.cluster_status()
  {:ok, [running_nodes: [:nonode@nohost]]}
  ```
  """
  @spec cluster_status() ::
          {:ok, [{:running_nodes, [node()]}]} | {:ok, [{:running_nodes, [node()]}, {:stopped_nodes, [node()]}]}
  def cluster_status do
    running = :mnesia.system_info(:running_db_nodes)
    stopped = :mnesia.system_info(:db_nodes) -- running

    if stopped == [] do
      {:ok, [{:running_nodes, running}]}
    else
      {:ok, [{:running_nodes, running}, {:stopped_nodes, stopped}]}
    end
  end

  @doc """
  Returns a list of running Mnesia cluster nodes.
  ## Example
  ```elixir
  iex(1)> Mnesiac.running_nodes()
  {:ok, [:nonode@nohost]}
  ```
  """
  @spec running_nodes() :: {:ok, [node()]}
  def running_nodes, do: {:ok, :mnesia.system_info(:running_db_nodes)}

  @doc """
  Is this node in the Mnesia cluster?
  ## Example
  ```elixir
  iex(1)> Mnesiac.node_in_cluster?(node())
  true
  ```
  """
  @spec node_in_cluster?(cluster_node :: node()) :: true | false
  def node_in_cluster?(cluster_node), do: Enum.member?(:mnesia.system_info(:db_nodes), cluster_node)

  @doc """
  Is this node running Mnesia?
  ## Example
  ```elixir
  iex(1)> Mnesiac.running_db_node?(node())
  true
  ```
  """
  @spec running_db_node?(cluster_node :: node()) :: true | false
  def running_db_node?(cluster_node) do
    {:ok, cluster} = running_nodes()
    Enum.member?(cluster, cluster_node)
  end

  defp filter_cluster(nodes), do: Enum.filter(Node.list(), fn node -> node in List.flatten(nodes) end)

  defp join_cluster(config, override, cluster_node) do
    with {:ok, config_struct} <- build_struct(config, override),
         :ok <- ensure_dir_exists(),
         :ok <- ensure_stopped(),
         :ok <- :mnesia.delete_schema([node()]),
         :ok <- ensure_started(),
         :ok <- connect(cluster_node),
         :ok <- copy_schema(config_struct, cluster_node),
         :ok <- copy_tables(config_struct, cluster_node),
         :ok <- ensure_tables_loaded(config_struct) do
      :ok
    else
      {:error, reason} ->
        Logger.debug(fn -> "[mnesiac:#{node()}] #{inspect(reason)}" end)
        {:error, reason}
    end
  end

  defp start(config, override) do
    with {:ok, config_struct} <- build_struct(config, override),
         :ok <- ensure_dir_exists(),
         :ok <- ensure_stopped(),
         :ok <- ensure_started(),
         :ok <- init_schema(config_struct),
         :ok <- init_tables(config_struct),
         :ok <- ensure_tables_loaded(config_struct) do
      :ok
    else
      {:error, reason} ->
        Logger.debug(fn -> "[mnesiac:#{node()}] #{inspect(reason)}" end)
        {:error, reason}
    end
  end

  defp ensure_dir_exists do
    mnesia_dir = :mnesia.system_info(:directory)

    with false <- File.exists?(mnesia_dir),
         :ok <- File.mkdir(mnesia_dir) do
      :ok
    else
      true -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_stopped do
    with :stopped <- :mnesia.stop(),
         :ok <- wait_for(:stop) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_struct(config, nil) do
    {:ok,
     struct!(
       __MODULE__,
       schema: build_struct(config, :schema),
       stores: Enum.map(Keyword.get(config, :stores, []), &struct!(Mnesiac.Store, &1)),
       store_load_timeout: Keyword.get(config, :store_load_timeout, 600_000)
     )}
  end

  defp build_struct(config, :schema) do
    struct!(
      Mnesiac.Store,
      Keyword.merge(
        Keyword.get(config, :schema, ram_copies: [1.0]),
        migrations: [],
        ref: :schema
      )
    )
  end

  defp build_struct(config, override) when is_function(override, 1) do
    case override.(config) do
      {:ok, config_struct} -> {:ok, config_struct}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_struct(_config, _unsupported), do: {:error, {:build_struct_failed, :unsupported_override_type}}

  defp ensure_started do
    with :ok <- :mnesia.start(),
         :ok <- wait_for(:start) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp connect(cluster_node) do
    case :mnesia.change_config(:extra_db_nodes, [cluster_node]) do
      {:ok, [_cluster_node]} -> :ok
      {:ok, []} -> {:error, {:failed_to_connect_node, cluster_node}}
      {:error, reason} -> {:error, reason}
    end
  end

  # TODO: fix schema
  defp copy_schema(config, cluster_node) do
    Enum.each(config.stores, fn store -> apply(store.ref, :copy_schema, [store, cluster_node]) end)
  end

  defp init_schema(config), do: Enum.each(config.stores, fn store -> apply(store.ref, :init_schema, [store]) end)

  defp copy_tables(config, cluster_node) do
    local_cookies = get_table_cookies()
    remote_cookies = get_table_cookies(cluster_node)

    Enum.each(config.stores, fn store ->
      cookie = Keyword.get(store.ref.store_options(), :record_name, store.ref)

      case {local_cookies[cookie], remote_cookies[cookie]} do
        {nil, nil} ->
          apply(store.ref, :init_store, [store])

        {nil, _} ->
          apply(store.ref, :copy_store, [store])

        {_, nil} ->
          {:error, {:no_remote_records_to_copy, store.ref, cluster_node}}

        {_local, _remote} ->
          apply(store.ref, :resolve_conflict, [config, cluster_node])
      end
    end)
  end

  defp init_tables(config) do
    case :mnesia.system_info(:extra_db_nodes) do
      [head | _tail] -> copy_tables(config, head)
      [] -> create_tables(config)
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_tables(config), do: Enum.each(config.stores, fn store -> apply(store.ref, :init_store, [store]) end)

  defp ensure_tables_loaded(config) do
    tables = :mnesia.system_info(:local_tables)

    case :mnesia.wait_for_tables(tables, config.store_load_timeout) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
      {:timeout, bad_tables} -> {:error, {:timeout, bad_tables}}
    end
  end

  defp wait_for(:start) do
    case :mnesia.system_info(:is_running) do
      :yes ->
        :ok

      :no ->
        {:error, :mnesia_unexpectedly_stopped}

      :stopping ->
        {:error, :mnesia_unexpectedly_stopping}

      :starting ->
        Process.sleep(1_000)
        wait_for(:start)
    end
  end

  defp wait_for(:stop) do
    case :mnesia.system_info(:is_running) do
      :no ->
        :ok

      :yes ->
        {:error, :mnesia_unexpectedly_running}

      :starting ->
        {:error, :mnesia_unexpectedly_starting}

      :stopping ->
        Process.sleep(1_000)
        wait_for(:stop)
    end
  end

  defp get_table_cookies(node \\ node()) do
    tables = :rpc.call(node, :mnesia, :system_info, [:tables])

    Enum.reduce(tables, %{}, fn t, acc ->
      Map.put(acc, t, :rpc.call(node, :mnesia, :table_info, [t, :cookie]))
    end)
  end
end
