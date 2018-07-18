defmodule Mnesiac.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link([_config, opts] = args) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def start_link([config]) do
    start_link([config, []])
  end

  @impl true
  def init([config, opts]) do
    opts = Keyword.put(opts, :strategy, :one_for_one)
    children = [{Mnesiam, [config]}]
    Supervisor.init(children, opts)
  end
end
