defmodule Mnesiac.Store do
  @moduledoc """
  This module defines a mnesiac store and contains overridable callbacks.
  """

  @doc """
  This function returns the store's configuration as a keyword list.
  For more information on the options supported here, see mnesia's documentation.
  ## Examples
  ```elixir
  iex> store_options()
  [attributes: [...], index: [:topic_id], disc_copies: [node()]]
  ```
  **Note**: Defining `:record_name` in `store_options()` will set the mnesia table name to the same.
  """
  @callback store_options() :: term

  @doc """
  This function is called by mnesiac either when it has no existing data to use or copy and will initialise a table
  ## Default Implementation
  ```elixir
  def init_store do
    :mnesia.create_table(Keyword.get(store_options(), :record_name, __MODULE__), store_options())
  end
  ```
  """
  @callback init_store() :: term

  @doc """
  This function is called by mnesiac when it joins a mnesia cluster and data for this store is found on the remote node in the cluster that is being connected to.
  ## Default Implementation
  ```elixir
  def copy_store do
    for type <- [:ram_copies, :disc_copies, :disc_only_copies] do
      value = Keyword.get(store_options(), type, [])

      if Enum.member?(value, node()) do
        :mnesia.add_table_copy(Keyword.get(store_options(), :record_name, __MODULE__), node(), type)
      end
    end
  end
  ```
  """
  @callback copy_store() :: term

  @doc ~S"""
  This function is called by mnesiac when it has detected data for a table on both the local node and the remote node of the cluster it is connecting to.
  ## Default Implementation
  ```elixir
  def resolve_conflict(cluster_node) do
    table_name = Keyword.get(store_options(), :record_name, __MODULE__)
    Logger.info(fn -> "[mnesiac:#{node()}] #{inspect(table_name)}: data found on both sides, copy aborted." end)

    :ok
  end
  ```
  **Note**: The default implementation for this function is to do nothing.
  """
  @callback resolve_conflict(node()) :: term

  @optional_callbacks copy_store: 0, init_store: 0, resolve_conflict: 1

  defmacro __using__(_) do
    quote do
      require Logger
      @behaviour Mnesiac.Store

      def init_store do
        :mnesia.create_table(Keyword.get(store_options(), :record_name, __MODULE__), store_options())
      end

      def copy_store do
        for type <- [:ram_copies, :disc_copies, :disc_only_copies] do
          value = Keyword.get(store_options(), type, [])

          if Enum.member?(value, node()) do
            :mnesia.add_table_copy(Keyword.get(store_options(), :record_name, __MODULE__), node(), type)
          end
        end
      end

      def resolve_conflict(cluster_node) do
        table_name = Keyword.get(store_options(), :record_name, __MODULE__)
        _ = Logger.info(fn -> "[mnesiac:#{node()}] #{inspect(table_name)}: data found on both sides, copy aborted." end)

        :ok
      end

      defoverridable Mnesiac.Store
    end
  end
end
