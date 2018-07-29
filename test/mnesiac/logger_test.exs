defmodule Mnesiac.LoggerTest do
  @moduledoc false
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Mnesiac.Logger

  doctest Mnesiac.Logger
  Application.put_env(:mnesiac, :debug, true)
  node = Node.self()

  for level <- [:debug, :info, :warn, :error] do
    describe "#{level}/1" do
      test "logs correctly" do
        output = capture_log(fn -> apply(Logger, unquote(level), ["some message"]) end)

        assert output =~ "[#{unquote(level)}]"
        assert output =~ "[mnesiac:#{unquote(node)}] some message"
      end
    end
  end
end
