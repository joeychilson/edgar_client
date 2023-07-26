defmodule EDGAR.MixProject do
  use Mix.Project

  @version "0.10.0"
  @description "An Elixir-based HTTP Client for SEC's EDGAR"

  def project do
    [
      app: :edgar_client,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: @description,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      mod: {EDGAR, []},
      extra_applications: [:logger, :req, :jason, :simple_rate_limiter]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.3.0"},
      {:simple_rate_limiter, "~> 1.0"},
      {:rustler, ">= 0.29.0", optional: true},
      {:rustler_precompiled, "~> 0.6"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "native",
        "checksum-*.exs",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/joeychilson/edgar_client"},
      maintainers: ["Joey Chilson"]
    ]
  end
end
