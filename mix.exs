defmodule FiFo.MixProject do
  use Mix.Project

  def project do
    [
      app: :fi_fo,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      source_url: "https://github.com/hrzndhrn/fi_fo",
      aliases: aliases(),
      preferred_cli_env: [
        carp: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.travis": :test,
        "coveralls.html": :test,
        "gen.test_suite": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    "This module provides (double-ended) FIFO queues in an efficient manner."
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/hrzndhrn/fi_fo"},
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*"
      ]
    ]
  end

  defp aliases do
    [bench: ["run bench/run.exs"]]
  end
end
