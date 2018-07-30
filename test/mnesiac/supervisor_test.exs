defmodule SupervisorTest do
  @moduledoc false
  use ExUnit.Case
  doctest Mnesiac.Supervisor

  test "mnesiac supervisor/1" do
    {:ok, pid} = Mnesiac.Supervisor.start_link([[:"test01@127.0.0.1", :"test02@127.0.0.1"]])

    assert Process.alive?(pid) == true
  end

  test "mnesiac supervisor/2" do
    {:ok, pid} =
      Mnesiac.Supervisor.start_link([[:"test01@127.0.0.1", :"test02@127.0.0.1"], [name: Mnesiac.SupervisorTest]])

    assert Process.alive?(pid) == true
  end
end
