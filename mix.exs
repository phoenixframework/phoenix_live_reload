defmodule PhoenixLiveReload.Mixfile do
  use Mix.Project

  @version "0.5.1"

  def project do
    [app: :phoenix_live_reload,
     version: @version,
     elixir: "~> 1.0.2 or ~> 1.1-dev",
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
    [applications: [:logger, :phoenix, :fs],
     mod: {Phoenix.LiveReload, []}]
  end

  defp deps do
    [{:phoenix, "~> 0.15"},
     {:fs, "~> 0.9.1"}]
  end
end
