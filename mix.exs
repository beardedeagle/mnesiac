defmodule Mnesiac.MixProject do
  @moduledoc false
  require Logger
  use Mix.Project

  def project do
    [
      app: :mnesiac,
      version: "0.4.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.json": :test,
        "coveralls.travis": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        flags: [
          "-Wunmatched_returns",
          "-Werror_handling",
          "-Wrace_conditions",
          "-Wno_opaque",
          "-Wunderspecs"
        ],
        plt_add_deps: :transitive
      ],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: [
        description: "Auto clustering for Mnesia made easy!",
        files: ["lib", ".formatter.exs", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
        maintainers: ["beardedeagle"],
        licenses: ["MIT"],
        links: %{GitHub: "https://github.com/beardedeagle/mnesiac"}
      ],
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"],
        formatters: ["html", "epub"]
      ],
      aliases: [
        check: [
          "format --check-formatted --dry-run",
          "compile --warning-as-errors --force",
          "credo --strict --all",
          "inch"
        ],
        "db.purge": &purge_db/1
      ],
      name: "Mnesiac",
      source_url: "https://github.com/beardedeagle/mnesiac",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mnesia]
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:libcluster, "~> 3.1", optional: true},
      {:credo, "~> 1.1", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: [:dev], runtime: false},
      {:ex_unit_clustered_case, "~> 0.4", only: [:dev, :test]},
      {:excoveralls, "~> 0.11", only: [:dev, :test], runtime: false},
      {:inch_ex, "~> 2.0", only: [:dev], runtime: false}
    ]
  end

  defp purge_db(_) do
    if Mix.env() in [:dev, :test] do
      Mix.shell().cmd("rm -rf ./test0* ./Mnesia.nonode@nohost")
    else
      Logger.info("[mnesiac:#{node()}] purge.db can only be used in dev and test env")
    end
  end
end
