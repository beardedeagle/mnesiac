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
    Logger.info(fn -> "[mnesiac:#{Node.self()}] mnesiac starting..." end)
    Mnesiac.init_mnesia(config)
    Logger.info(fn -> "[mnesiac:#{Node.self()}] mnesiac started" end)
    opts = Keyword.put(opts, :strategy, :one_for_one)
    Supervisor.init([], opts)
  end
end
