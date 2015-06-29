defmodule PhoenixLiveReload.Mixfile do
  use Mix.Project

  @version "0.4.2"

  def project do
    [app: :phoenix_live_reload,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,

     # Hex
     description: "Provides live-reload functionality for Phoenix",
     package: package,

     # Docs
     name: "Phoenix Live-Reload",
     docs: [source_ref: "v#{@version}",
            source_url: "https://github.com/phoenixframework/phoenix_live_reload"]]
  end

  defp package do
    [contributors: ["Chris McCord"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/phoenixframework/phoenix_live_reload"}]
  end

  def application do
    [applications: [:logger, :phoenix, :fs]]
  end

  defp deps do
    [{:phoenix, "~> 0.13 or ~> 0.14"},
     {:fs, "~> 0.9.1"}]
  end
end
