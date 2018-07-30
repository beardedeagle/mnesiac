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

  test "cluster status" do
    assert Mnesiac.cluster_status == [{:running_nodes, [Node.self()]}]
  end

  test "running nodes" do
    assert Mnesiac.running_nodes == [Node.self()]
  end

  test "node in cluster" do
    assert Mnesiac.node_in_cluster?(Node.self()) == true
  end

  test "running db node" do
    assert Mnesiac.running_db_node?(Node.self()) == true
  end
end
