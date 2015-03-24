Application.put_env(:phoenix, MyApp,
  live_reload: [url: "ws://localhost:4000", patterns: [~r/some\/path/]])

defmodule MyApp do
  use Phoenix.Endpoint, otp_app: :phoenix
end

MyApp.start_link()
ExUnit.start()
