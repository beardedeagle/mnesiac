defmodule Mnesiac.Supervisor do
  @moduledoc false
  require Logger
  use Supervisor

  def start_link([_config, opts] = args) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def start_link([config]) do
    start_link([config, []])
  end

  @impl true
  def init([config, opts]) do
    Logger.info("[mnesiac:#{node()}] mnesiac starting...")
    :ok = Mnesiac.init_mnesia(config)
    Logger.info("[mnesiac:#{node()}] mnesiac started")

    opts = Keyword.put(opts, :strategy, :one_for_one)
    Supervisor.init([], opts)
  end
end
