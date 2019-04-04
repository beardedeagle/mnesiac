defmodule Mnesiac.Supervisor do
  @moduledoc """
  Mnesiac supervisor.
  """
  use Supervisor

  @typedoc """
  Default arguments expected to be passed in to Mnesiac. `override` is optional.
  """
  @type arg ::
          {:cluster, [node()]}
          | {:config, config}
          | {:override, (config -> {:ok, struct()} | {:error, term()}) | nil}

  @typedoc """
  Default implementation of arguments expected to be passed in to Mnesiac.
  """
  @type args :: [arg]

  @typedoc """
  Default configuration expected to be passed in to Mnesiac. `store_load_timeout` is optional.
  """
  @type config :: {:schema, store} | {:stores, [store, ...]} | {:store_load_timeout, integer()}

  @typedoc """
  Default store configuration expected to be passed in to Mnesiac. Everything is optional except `ref`.
  """
  @type store ::
          {:ref, module() | atom()}
          | {:ram_copies, [non_neg_integer() | float() | node()]}
          | {:disc_copies, [non_neg_integer() | float() | node()]}
          | {:disc_only_copies, [non_neg_integer() | float() | node()]}
          | {:blacklist, [node()]}
          | {:migrations, [mfa()]}

  @doc """
  Entry point for Mnesiac when used in a supervision tree.
  """
  @spec start_link(args :: [args | keyword()] | args) :: :ignore | {:error, term()} | {:ok, pid()}
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
