defmodule Mnesiac.Supervisor do
  @moduledoc """
  Mnesiac supervisor.

  TODO: Docs, probably talk about configuration to be passed in or type it out.
  """
  use Supervisor

  @doc """
  Entry point for Mnesiac when used in a supervision tree.
  """
  @spec start_link(
          args :: [[cluster: [node()], config: keyword()] | keyword()] | [cluster: [node()], config: keyword()]
        ) ::
          :ignore | {:error, term()} | {:ok, pid()}
  def start_link([[cluster: _cluster, config: _config], opts] = args) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def start_link([cluster: _cluster, config: _config] = args) do
    start_link([args, []])
  end

  @impl true
  def init([config, opts]) do
    Mnesiac.init_mnesia(config)
    opts = Keyword.put(opts, :strategy, :one_for_one)
    Supervisor.init([], opts)
  end
end
