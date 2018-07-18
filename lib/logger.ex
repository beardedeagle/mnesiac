defmodule Mnesiac.Logger do
  @moduledoc false
  require Logger

  def debug(msg) do
    case Application.get_env(:mnesiac, :debug, false) do
      dbg when dbg in [nil, false, "false"] ->
        :ok

      _ ->
        log(:debug, msg)
    end
  end

  def info(msg), do: log(:info, msg)
  def warn(msg), do: log(:warn, msg)
  def error(msg), do: log(:error, msg)

  defp log(level, msg), do: Logger.log(level, "[mnesiac:#{Node.self()}] #{msg}")
end
