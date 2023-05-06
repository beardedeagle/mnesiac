defmodule StoreManagerTest do
  @moduledoc false
  use ExUnit.Case

  describe "get_table_cookies" do
    test "returns an error when the node is not reachable" do
      assert {:error, _} = Mnesiac.StoreManager.get_table_cookies(:missing_node@missing_host)
    end
  end
end
