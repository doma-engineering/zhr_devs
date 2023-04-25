defmodule ZhrDevs.MixProject do
  use Mix.Project

  def project do
    [
      app: :zhr_devs,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ZhrDevs.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:doma_oauth, github: "doma-engineering/doma_oauth", branch: "main"},
      {:algae_goo, github: "doma-engineering/algae-goo", branch: "main"},
      {:uptight, github: "doma-engineering/uptight", branch: "main"},

      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
