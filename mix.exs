defmodule ZhrDevs.MixProject do
  use Mix.Project

  def project do
    [
      app: :zhr_devs,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :bamboo, :bamboo_smtp],
      mod: {ZhrDevs.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:corsica, "~> 1.3"},
      {:doma_oauth, github: "doma-engineering/doma_oauth", tag: "0.1.1"},
      {:algae_goo, github: "doma-engineering/algae-goo", branch: "main"},
      {:witchcraft_goo, github: "doma-engineering/witchcraft-goo", branch: "main"},
      {:uptight, github: "doma-engineering/uptight", branch: "main"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},

      # Testing
      {:stream_data, "~> 0.5.0", only: [:test]},
      {:hammox, "~> 0.7", only: :test},

      # Event sourcing / CQRS
      {:commanded, "~> 1.4"},
      {:jason, "~> 1.3"},
      {:eventstore, "~> 1.4"},
      {:commanded_eventstore_adapter, "~> 1.4"},

      # Emails
      {:bamboo_smtp, "~> 4.2"},
      {:mime, "~> 1.0 or ~> 2.0"}
    ]
  end
end
