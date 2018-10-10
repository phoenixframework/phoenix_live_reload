defmodule PhoenixLiveReload.Mixfile do
  use Mix.Project

  @version "1.1.7"

  def project do
    [app: :phoenix_live_reload,
     version: @version,
     elixir: "~> 1.3",
     deps: deps(),

     # Hex
     description: "Provides live-reload functionality for Phoenix",
     package: package(),

     # Docs
     name: "Phoenix Live-Reload",
     docs: [source_ref: "v#{@version}",
            source_url: "https://github.com/phoenixframework/phoenix_live_reload"]]
  end

  defp package do
    [
      maintainers: ["Chris McCord", "José Valim"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/phoenixframework/phoenix_live_reload"}
    ]
  end

  def application do
    [
      mod: {Phoenix.LiveReloader.Application, []},
      applications: [:logger, :phoenix, :file_system]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.0 or ~> 1.2 or ~> 1.3 or ~> 1.4"},
      {:ex_doc, "~> 0.19", only: :docs},
      {:earmark, ">= 0.0.0", only: :docs},
      {:file_system, "~> 0.2.1 or ~> 0.3"},
    ]
  end
end
