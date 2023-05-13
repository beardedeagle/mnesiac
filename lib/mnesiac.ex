defmodule Mnesiac do
  @moduledoc """
  Mnesiac Manager
  """
  require Logger
  alias Mnesiac.StoreManager

  @doc """
  Start Mnesia with strict host checking
  """
  def init_mnesia(nodes) do
    nodes =
      Enum.filter(Node.list(), fn node ->
        node in List.flatten(nodes)
      end)

    case nodes do
      [head | _tail] ->
        join_cluster(head)

      [] ->
        start()
    end
  end

  @doc """
  Start Mnesia alone
  """
  def start do
    with :ok <- ensure_dir_exists(),
         :ok <- ensure_started(),
         :ok <- StoreManager.copy_schema(node()),
         :ok <- StoreManager.init_tables(),
         :ok <- StoreManager.ensure_tables_loaded() do
      :ok
    else
      {:error, reason} ->
        _ = Logger.debug(fn -> "[mnesiac:#{node()}] #{inspect(reason)}" end)
        {:error, reason}
    end
  end

  @doc """
  Join to a Mnesia cluster
  """
  def join_cluster(cluster_node) do
    with :ok <- ensure_dir_exists(),
         :ok <- ensure_stopped(),
         :ok <- StoreManager.delete_schema(),
         :ok <- ensure_started(),
         :ok <- connect(cluster_node),
         :ok <- StoreManager.copy_schema(node()),
         :ok <- StoreManager.copy_tables(cluster_node),
         :ok <- StoreManager.ensure_tables_loaded() do
      :ok
    else
      {:error, reason} ->
        _ = Logger.debug(fn -> "[mnesiac:#{node()}] #{inspect(reason)}" end)
        {:error, reason}
    end
  end

  @doc """
  Cluster status
  """
  def cluster_status do
    running = :mnesia.system_info(:running_db_nodes)
    stopped = :mnesia.system_info(:db_nodes) -- running

    if stopped == [] do
      [{:running_nodes, running}]
    else
      [{:running_nodes, running}, {:stopped_nodes, stopped}]
    end
  end

  @doc """
  Cluster with a node
  """
  def connect(cluster_node) do
    case :mnesia.change_config(:extra_db_nodes, [cluster_node]) do
      {:ok, [_cluster_node]} ->
        :ok

      {:ok, []} ->
        {:error, {:failed_to_connect_node, cluster_node}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Running Mnesia nodes
  """
  def running_nodes do
    :mnesia.system_info(:running_db_nodes)
  end

  @doc """
  Is node in Mnesia cluster?
  """
  def node_in_cluster?(cluster_node) do
    Enum.member?(:mnesia.system_info(:db_nodes), cluster_node)
  end

  @doc """
  Is running Mnesia node?
  """
  def running_db_node?(cluster_node) do
    Enum.member?(running_nodes(), cluster_node)
  end

  defp ensure_started do
    with :ok <- start_server(),
         :ok <- wait_for(:start) do
      :ok
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_stopped do
    with :stopped <- stop_server(),
         :ok <- wait_for(:stop) do
      :ok
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_dir_exists do
    mnesia_dir = :mnesia.system_info(:directory)

    with false <- File.exists?(mnesia_dir),
         :ok <- File.mkdir(mnesia_dir) do
      :ok
    else
      true ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp start_server do
    :mnesia.start()
  end

  defp stop_server do
    :mnesia.stop()
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
end
