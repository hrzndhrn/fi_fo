defmodule FiFo.MixProject do
  use Mix.Project

  def project do
    [
      app: :fi_fo,
      version: "0.2.0",
      elixir: "~> 1.11",
      name: "FiFo",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      source_url: "https://github.com/hrzndhrn/fi_fo",
      aliases: aliases(),
      docs: [main: "FiFo"],
      preferred_cli_env: [
        carp: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.github": :test,
        "coveralls.html": :test
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
      {:benchee_dsl, "~> 0.5", only: :dev},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11", only: :test},
      {:prove, "~> 0.1", only: [:dev, :test]},
      {:recode, "~> 0.4", only: :dev}
    ]
  end

  defp aliases do
    [
      carp: "test --seed 0 --max-failures 1"
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/hrzndhrn/fi_fo"},
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*"
      ]
    ]
  end
end
