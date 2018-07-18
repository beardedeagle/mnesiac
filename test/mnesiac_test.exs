defmodule MnesiacTest do
  @moduledoc false
  use ExUnit.Case
  doctest Mnesiac

  test "greets the world" do
    assert Mnesiac.hello() == :world
  end
end
