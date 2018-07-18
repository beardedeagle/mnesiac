defmodule Mnesiac do
  @moduledoc """
  Mnesiac Manager
  """
  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    GenServer.cast(__MODULE__, {:init, args})

    {:ok, []}
  end

  @impl true
  def handle_cast({:init, nodes}, _state) do
    init_mnesia(nodes)

    {:noreply, []}
  end

  @doc """
  Start Mnesia with/without a cluster
  """
  def init_mnesia(nodes) do
    nodes =
      Enum.filter(List.delete(Node.list(), Node.self()), fn node ->
        node in List.delete(List.flatten(nodes), Node.self())
      end)

    case nodes do
      [h | _t] -> join_cluster(h)
      [] -> start()
    end
  end

  @doc """
  Start Mnesia with/without a cluster. Test helper.
  """
  def init_mnesia(nodes, :test) do
    case List.delete(List.flatten(nodes), Node.self()) do
      [h | _t] -> join_cluster(h)
      [] -> start()
    end
  end

  @doc """
  Start Mnesia alone
  """
  def start do
    with :ok <- ensure_dir_exists(),
         :ok <- start_server(),
         :ok <- Store.copy_schema(Node.self()),
         :ok <- Store.init_tables(),
         :ok <- Store.ensure_tables_loaded() do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Join to a Mnesia cluster
  """
  def join_cluster(cluster_node) do
    with :ok <- ensure_stopped(),
         :ok <- Store.delete_schema(),
         :ok <- ensure_started(),
         :ok <- connect(cluster_node),
         :ok <- Store.copy_schema(Node.self()),
         :ok <- Store.copy_tables(),
         :ok <- Store.ensure_tables_loaded() do
      :ok
    else
      {:error, reason} ->
        Logger.log(:debug, fn -> inspect(reason) end)
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
      {:ok, [_cluster_node]} -> :ok
      {:ok, []} -> {:error, {:failed_to_connect_node, cluster_node}}
      reason -> {:error, reason}
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
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_stopped do
    with :stopped <- stop_server(),
         :ok <- wait_for(:stop) do
      :ok
    else
      {:error, reason} -> {:error, reason}
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
        Logger.log(:debug, fn -> inspect(reason) end)
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
