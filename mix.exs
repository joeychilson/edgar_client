defmodule EDGAR.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "A client for the SEC's EDGAR system"

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
      extra_applications: [:logger, :httpoison, :jason, :simple_rate_limiter]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:simple_rate_limiter, "~> 0.2.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/joeychilson/edgar_client"},
      maintainers: ["Joey Chilson"]
    ]
  end
end
