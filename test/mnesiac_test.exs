defmodule MnesiacTest do
  @moduledoc false
  use ExUnit.ClusteredCase, async: false

  @single_unnamed_opts [
    boot_timeout: 10_000,
    config: [mnesia: [dir: to_charlist(Path.join(File.cwd!(), "test01"))]],
    nodes: [[name: :"test01@127.0.0.1"]]
  ]

  @single_named_opts [
    boot_timeout: 10_000,
    config: [mnesia: [dir: to_charlist(Path.join(File.cwd!(), "test02"))]],
    nodes: [[name: :"test02@127.0.0.1"]]
  ]

  @distributed_opts [
    boot_timeout: 10_000,
    nodes: [
      [
        name: :"test03@127.0.0.1",
        config: [mnesia: [dir: to_charlist(Path.join(File.cwd!(), "test03"))]]
      ],
      [
        name: :"test04@127.0.0.1",
        config: [mnesia: [dir: to_charlist(Path.join(File.cwd!(), "test04"))]]
      ]
    ]
  ]

  scenario "single node test with mnesiac supervisor/1", @single_unnamed_opts do
    node_setup do
      config = [
        schema: [disc_copies: [node()]],
        stores: [[ref: Mnesiac.Support.ExampleStoreOne, disc_copies: [node()]]],
        store_load_timeout: 600_000
      ]

      {:ok, _pid} = Mnesiac.Supervisor.start_link(cluster: [node()], config: config)
      :ok = :mnesia.wait_for_tables([Mnesiac.Support.ExampleStoreOne], 5000)
    end

    test "cluster status", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert {:ok, [{:running_nodes, [node_a]}]} = Cluster.call(node_a, Mnesiac, :cluster_status, [])
    end

    test "running nodes", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert {:ok, [node_a]} = Cluster.call(node_a, Mnesiac, :running_nodes, [])
    end

    test "node in cluster", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert true = Cluster.call(node_a, Mnesiac, :node_in_cluster?, [node_a])
    end

    test "running db node", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert true = Cluster.call(node_a, Mnesiac, :running_db_node?, [node_a])
    end

    test "tables exist", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      tables = Cluster.call(node_a, :mnesia, :system_info, [:tables])

      assert true = Cluster.call(node_a, Enum, :member?, [tables, :schema])
      assert true = Cluster.call(node_a, Enum, :member?, [tables, ExampleStoreOne])
      assert :opt_disc = Cluster.call(node_a, :mnesia, :system_info, [:schema_location])
    end
  end

  scenario "single node test with mnesiac supervisor/2", @single_named_opts do
    node_setup do
      config = [
        schema: [disc_copies: [node()]],
        stores: [[ref: Mnesiac.Support.ExampleStoreOne, disc_copies: [node()]]],
        store_load_timeout: 600_000
      ]

      {:ok, _pid} =
        Mnesiac.Supervisor.start_link([[cluster: [node()], config: config], [name: Mnesiac.SupervisorSingleTest]])

      :ok = :mnesia.wait_for_tables([Mnesiac.Support.ExampleStoreOne], 5000)
    end

    test "cluster status", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert {:ok, [running_nodes: [node_a]]} = Cluster.call(node_a, Mnesiac, :cluster_status, [])
    end

    test "running nodes", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert {:ok, [node_a]} = Cluster.call(node_a, Mnesiac, :running_nodes, [])
    end

    test "node in cluster", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert true = Cluster.call(node_a, Mnesiac, :node_in_cluster?, [node_a])
    end

    test "running db node", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      assert true = Cluster.call(node_a, Mnesiac, :running_db_node?, [node_a])
    end

    test "tables exist", %{cluster: cluster} do
      [node_a] = Cluster.members(cluster)

      tables = Cluster.call(node_a, :mnesia, :system_info, [:tables])

      assert true = Cluster.call(node_a, Enum, :member?, [tables, :schema])
      assert true = Cluster.call(node_a, Enum, :member?, [tables, ExampleStoreOne])
      assert :opt_disc = Cluster.call(node_a, :mnesia, :system_info, [:schema_location])
    end
  end

  scenario "distributed test", @distributed_opts do
    node_setup do
      config = [
        schema: [disc_copies: [node()]],
        stores: [
          [ref: Mnesiac.Support.ExampleStoreOne, disc_copies: [node()]],
          [ref: Mnesiac.Support.ExampleStoreTwo, disc_copies: [node()]]
        ],
        store_load_timeout: 600_000
      ]

      {:ok, _pid} =
        Mnesiac.Supervisor.start_link([
          [cluster: [:"test03@127.0.0.1", :"test04@127.0.0.1"], config: config],
          [name: Mnesiac.SupervisorSingleTest]
        ])

      if node() == :"test03@127.0.0.1" do
        :ok = :mnesia.wait_for_tables([Mnesiac.Support.ExampleStoreOne, Mnesiac.Support.ExampleStoreTwo], 5000)
      else
        :ok = :mnesia.wait_for_tables([Mnesiac.Support.ExampleStoreOne, Mnesiac.Support.ExampleStoreTwo], 10_000)
      end
    end

    test "cluster status", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      assert {:ok, [running_nodes: [node_a, node_b]]} = Cluster.call(node_a, Mnesiac, :cluster_status, [])
      assert {:ok, [running_nodes: [node_a, node_b]]} = Cluster.call(node_b, Mnesiac, :cluster_status, [])
    end

    test "running nodes", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      assert {:ok, [node_a, node_b]} = Cluster.call(node_a, Mnesiac, :running_nodes, [])
      assert {:ok, [node_a, node_b]} = Cluster.call(node_b, Mnesiac, :running_nodes, [])
    end

    test "node in cluster", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      assert true = Cluster.call(node_a, Mnesiac, :node_in_cluster?, [node_b])
      assert true = Cluster.call(node_b, Mnesiac, :node_in_cluster?, [node_a])
    end

    test "running db node", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      assert true = Cluster.call(node_a, Mnesiac, :running_db_node?, [node_b])
      assert true = Cluster.call(node_b, Mnesiac, :running_db_node?, [node_a])
    end

    test "tables exist", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      tables_a = Cluster.call(node_a, :mnesia, :system_info, [:tables])
      tables_b = Cluster.call(node_b, :mnesia, :system_info, [:tables])

      assert true = Cluster.call(node_a, Enum, :member?, [tables_a, :schema])
      assert true = Cluster.call(node_b, Enum, :member?, [tables_b, :schema])
      assert true = Cluster.call(node_a, Enum, :member?, [tables_a, ExampleStoreOne])
      assert true = Cluster.call(node_a, Enum, :member?, [tables_a, ExampleStoreTwo])
      assert true = Cluster.call(node_b, Enum, :member?, [tables_b, ExampleStoreOne])
      assert true = Cluster.call(node_b, Enum, :member?, [tables_b, ExampleStoreTwo])
      assert :opt_disc = Cluster.call(node_a, :mnesia, :system_info, [:schema_location])
      assert :opt_disc = Cluster.call(node_b, :mnesia, :system_info, [:schema_location])
    end
  end
end
