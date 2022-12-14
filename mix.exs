defmodule FootballResults.MixProject do
  use Mix.Project

  def project do
    [
      app: :football_results,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FootballResults.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:exprotobuf, "~> 1.2"},
      {:distillery, "~> 2.0"},
      {:folsomite, "~> 1.2"}
    ]
  end
end
