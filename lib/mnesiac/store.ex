defmodule Mnesiac.Store do
  @moduledoc """
  Defines an mnesiac store and contains overridable callbacks.
  """

  @typedoc """
  Default store configuration expected to be passed in to Mnesiac. Everything is optional except `ref`.
  """
  @type config ::
          {:ref, module() | atom()}
          | {:ram_copies, [non_neg_integer() | float() | node()]}
          | {:disc_copies, [non_neg_integer() | float() | node()]}
          | {:disc_only_copies, [non_neg_integer() | float() | node()]}
          | {:blacklist, [node()]}
          | {:migrations, [mfa()]}

  @typedoc """
  Defines the configuration of an mnesiac store.
  ## Example
  ```elixir
  %Mnesiac.Store{
    blacklist: [:"test22@127.0.0.1"],
    disc_copies: [1.0],
    disc_only_copies: [],
    migrations: [],
    ram_copies: [],
    ref: Mnesiac.Support.ExampleStore
  }
  ```
  """
  @type t :: %__MODULE__{
          ref: module() | atom(),
          ram_copies: [non_neg_integer() | float() | node()],
          disc_copies: [non_neg_integer() | float() | node()],
          disc_only_copies: [non_neg_integer() | float() | node()],
          blacklist: [node()],
          migrations: [mfa()]
        }

  @enforce_keys [:ref]
  defstruct ref: nil,
            ram_copies: [],
            disc_copies: [],
            disc_only_copies: [],
            blacklist: [],
            migrations: []

  @doc """
  Returns ths store's configuration as a keyword list.
  For more information on the options supported here, please see mnesia's documenatation.
  ## Example
  ```elixir
  iex(1)> store_options()
  [attributes: [...], index: [:topic_id], disc_copies: [node()]]
  ```
  **Note**: Defining `:record_name` in `store_options()` will set the mnesia store name to the same.
  """
  @callback store_options() :: keyword()

  @doc """
  Called by mnesiac to initialize mnesia's schema.
  ## Default Implementation
  ```elixir
  def init_schema(config) do
    :ok
  end
  ```
  """
  @callback init_schema(config :: struct()) :: term()

  @doc """
  Called by mnesiac to copy mnesia's schema.
  ## Default Implementation
  ```elixir
  def copy_schema(config) do
    :ok
  end
  ```
  """
  @callback copy_schema(config :: struct(), cluster_node :: node()) :: term()

  @doc """
  Called by mnesiac either when it has no existing records to use or copy and will initialize a store.
  ## Default Implementation
  ```elixir
  def init_store(config) do
    :mnesia.create_table(Keyword.get(store_options(), :record_name, __MODULE__), store_options())
  end
  ```
  """
  @callback init_store(config :: struct()) :: term()

  @doc """
  Called by mnesiac when it joins a mnesia cluster and records for this store is found on the remote node being connected to.
  ## Default Implementation
  ```elixir
  def copy_store(config) do
    for type <- [:ram_copies, :disc_copies, :disc_only_copies] do
      value = Keyword.get(store_options(), type, [])
      if Enum.member?(value, node()) do
        :mnesia.add_table_copy(Keyword.get(store_options(), :record_name, __MODULE__), node(), type)
      end
    end
  end
  ```
  """
  @callback copy_store(config :: struct()) :: term()

  @doc """
  Called by mnesiac when migrations are to be performed.
  ## Default Implementation
  ```elixir
  def init_migration(config) do
    :ok
  end
  ```
  """
  @callback init_migration(config :: struct()) :: term()

  @doc """
  Called by mnesiac when migrations are to be rolled back.
  ## Default Implementation
  ```elixir
  def rollback_migration(config) do
    :ok
  end
  ```
  """
  @callback rollback_migration(config :: struct()) :: term()

  @doc """
  Called by user when the cluster needs to be refreshed.
  ## Default Implementation
  ```elixir
  def refresh_cluster(config) do
    :ok
  end
  ```
  """
  @callback refresh_cluster(config :: struct()) :: term()

  @doc """
  Called by user when the cluster needs to be refreshed.
  ## Default Implementation
  ```elixir
  def backup(config) do
    :ok
  end
  ```
  """
  @callback backup(config :: struct()) :: term()

  @doc ~S"""
  Called by mnesiac when it has detected records for a store on both the local and remote nodes it is connecting to.
  ## Default Implementation
  ```elixir
  def resolve_conflict(_config, cluster_node) do
    store_name = Keyword.get(store_options(), :record_name, __MODULE__)
    Logger.info("[mnesiac:#{node()}] #{inspect(store_name)}: records found on both sides, copy aborted.")
    :ok
  end
  ```
  **Note**: The default implementation is to do nothing.
  """
  @callback resolve_conflict(config :: struct(), cluster_node :: node()) :: term()

  @optional_callbacks init_schema: 1,
                      copy_schema: 2,
                      init_store: 1,
                      copy_store: 1,
                      init_migration: 1,
                      rollback_migration: 1,
                      refresh_cluster: 1,
                      backup: 1,
                      resolve_conflict: 2

  defmacro __using__(_) do
    quote do
      require Logger
      @behaviour Mnesiac.Store

      def init_schema(config), do: copy_schema(config, node())

      def copy_schema(config, cluster_node) do
        copy_type = config.schema

        case :mnesia.change_table_copy_type(:schema, cluster_node, copy_type) do
          {:atomic, :ok} -> :ok
          {:aborted, {:already_exists, :schema, _, _}} -> :ok
          {:aborted, reason} -> {:error, reason}
        end
      end

      def init_store(config) do
        :mnesia.create_table(Keyword.get(store_options(), :record_name, __MODULE__), store_options())
      end

      def copy_store(config) do
        for type <- [:ram_copies, :disc_copies, :disc_only_copies] do
          value = Keyword.get(store_options(), type, [])

          if Enum.member?(value, node()) do
            :mnesia.add_table_copy(Keyword.get(store_options(), :record_name, __MODULE__), node(), type)
          end
        end
      end

      def init_migration(_config) do
        :ok
      end

      def rollback_migration(_config) do
        :ok
      end

      def refresh_cluster(_config) do
        :ok
      end

      def backup(_config) do
        :ok
      end

      def resolve_conflict(_config, cluster_node) do
        store_name = Keyword.get(store_options(), :record_name, __MODULE__)
        Logger.info("[mnesiac:#{node()}] #{inspect(store_name)}: records found on both sides, copy aborted.")

        :ok
      end

      defoverridable Mnesiac.Store
    end
  end
end
