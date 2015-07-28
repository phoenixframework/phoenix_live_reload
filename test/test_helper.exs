Application.put_env(:phoenix_live_reload, MyApp.Endpoint,
  pubsub: [adapter: Phoenix.PubSub.PG2, name: Phoenix.LiveReload.PubSub],
  live_reload:
    [url: "ws://localhost:4000",
     patterns: [
       ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
       ~r{web/views/.*(ex)$},
       ~r{web/templates/.*(eex)$}
     ]])

defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_live_reload
end

MyApp.Endpoint.start_link()
ExUnit.start()
