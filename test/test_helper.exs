{_response, 0} = System.cmd("epmd", ["-daemon"])
{:ok, _pid} = Node.start(:"primary@127.0.0.1", :longnames)
{:ok, _app} = Application.ensure_all_started(:ex_unit_clustered_case)

ExUnit.start()
