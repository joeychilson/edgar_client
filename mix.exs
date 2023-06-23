defmodule EdgarClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :edgar_client,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {EDGARClient, []},
      extra_applications: [:logger, :httpoison, :jason, :simple_rate_limiter]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:simple_rate_limiter, "~> 0.2.0"}
    ]
  end
end
