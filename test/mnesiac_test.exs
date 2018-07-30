defmodule MnesiacTest do
  @moduledoc false
  use ExUnit.Case
  doctest Mnesiac

  setup_all do
    node = Node.self()
    Mnesiac.init_mnesia([node])

    :ok
  end

  test "tables exist" do
    tables = :mnesia.system_info(:tables)

    assert Enum.member?(tables, :schema) == true
    assert Enum.member?(tables, ExampleStore) == true
    assert :mnesia.system_info(:schema_location) == :opt_disc
  end
end
