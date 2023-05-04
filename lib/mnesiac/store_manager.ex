defmodule Mnesiac.StoreManager do
  @moduledoc """
  Mnesia Store Manager
  """
  require Logger

  @doc """
  Init tables
  """
  def init_tables do
    case :mnesia.system_info(:extra_db_nodes) do
      [head | _tail] ->
        copy_tables(head)

      [] ->
        create_tables()
    end
  end

  @doc """
  Ensure tables loaded
  """
  def ensure_tables_loaded do
    tables = :mnesia.system_info(:local_tables)

    case :mnesia.wait_for_tables(tables, table_load_timeout()) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, reason}

      {:timeout, bad_tables} ->
        {:error, {:timeout, bad_tables}}
    end
  end

  @doc """
  Create tables
  """
  def create_tables do
    Enum.each(stores(), fn data_mapper ->
      apply(data_mapper, :init_store, [])
    end)

    :ok
  end

  @doc """
  Copy tables
  """
  def copy_tables(cluster_node) do
    local_cookies = get_table_cookies()
    remote_cookies = get_table_cookies(cluster_node)

    Enum.each(stores(), fn data_mapper ->
      cookie = Keyword.get(data_mapper.store_options(), :record_name, data_mapper)

      case {local_cookies[cookie], remote_cookies[cookie]} do
        {nil, nil} ->
          apply(data_mapper, :init_store, [])

        {nil, _} ->
          apply(data_mapper, :copy_store, [])

        {_, nil} ->
          Logger.info("[mnesiac:#{node()}] #{inspect(data_mapper)}: no remote data to copy found.")
          {:error, :no_remote_data_to_copy}

        {_local, _remote} ->
          apply(data_mapper, :resolve_conflict, [cluster_node])
      end
    end)

    :ok
  end

  @doc """
  Copy schema
  """
  def copy_schema(cluster_node) do
    copy_type = Application.get_env(:mnesiac, :schema_type, :ram_copies)

    case :mnesia.change_table_copy_type(:schema, cluster_node, copy_type) do
      {:atomic, :ok} ->
        :ok

      {:aborted, {:already_exists, :schema, _, _}} ->
        :ok

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Delete schema
  """
  def delete_schema do
    :mnesia.delete_schema([node()])
  end

  @doc """
  Delete schema copy
  """
  def del_schema_copy(cluster_node) do
    case :mnesia.del_table_copy(:schema, cluster_node) do
      {:atomic, :ok} ->
        :ok

      {:aborted, reason} ->
        {:error, reason}
    end
  end

  defp stores do
    Application.get_env(:mnesiac, :stores)
  end

  defp table_load_timeout do
    Application.get_env(:mnesiac, :table_load_timeout, 600_000)
  end

  @doc """
  This function returns a map of tables and their cookies.
  """
  def get_table_cookies(node \\ node()) do
    tables = :rpc.call(node, :mnesia, :system_info, [:local_tables])

    Enum.reduce(tables, %{}, fn t, acc ->
      Map.put(acc, t, :rpc.call(node, :mnesia, :table_info, [t, :cookie]))
    end)
  end
end
