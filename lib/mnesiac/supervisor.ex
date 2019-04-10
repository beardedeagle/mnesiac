defmodule Mnesiac.Supervisor do
  @moduledoc """
  Mnesiac supervisor.
  """
  use Supervisor

  @doc """
  Entry point for Mnesiac when used in a supervision tree.
  """
  @spec start_link(init_arg :: [Mnesiac.init_arg() | keyword()] | Mnesiac.init_arg()) ::
          :ignore | {:error, term()} | {:ok, pid()}
  def start_link([[cluster: _cluster, config: _config], opts] = init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, opts)
  end

  def start_link([cluster: _cluster, config: _config] = init_arg) do
    start_link([init_arg, []])
  end

  @impl true
  def init([config, opts]) do
    Mnesiac.init_mnesia(config)
    opts = Keyword.put(opts, :strategy, :one_for_one)
    Supervisor.init([], opts)
  end
end
