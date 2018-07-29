defmodule Mnesiac.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :mnesiac,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
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
        description: "Autoclustering for mnesia made easy!",
        files: ["lib", ".formatter.exs", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
        maintainers: ["beardedeagle"],
        licenses: ["MIT"],
        links: %{GitHub: "https://github.com/beardedeagle/mnesiac"}
      ],
      aliases: [
        check: ["format", "compile --force", "credo --strict --all"],
        test: "coveralls.html --trace --slowest 10"
      ],
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
      {:libcluster, "~> 3.0", optional: true},
      {:credo, "~> 0.10", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19", only: [:dev], runtime: false},
      {:ex_unit_clustered_case, github: "bitwalker/ex_unit_clustered_case"},
      {:excoveralls, "~> 0.9", only: [:dev, :test], runtime: false}
    ]
  end
end
