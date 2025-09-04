defmodule ElixirWebTerminal.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_web_terminal,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description:
        "A minimal Elixir application that serves a real terminal in the browser using Plug and Cowboy.",
      package: [
        name: "exterm",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/metehan/exterm"}
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirWebTerminal.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.7"}
    ]
  end
end
