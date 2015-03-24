defmodule PhoenixLiveReloadTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  Application.put_env(:phoenix, __MODULE__.Endpoint,
    live_reload: [url: "ws://localhost:4000", patterns: [~r/some\/path/]])

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :phoenix
  end

  setup_all do
    Endpoint.start_link()
    :ok
  end

  test "injects live_reload for html requests if configured" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn(:get, "/")
           |> Plug.Conn.put_private(:phoenix_endpoint, Endpoint)
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "")
    assert to_string(conn.resp_body) |> String.contains?("<iframe src=\"/phoenix/live-reloader\" width=\"0\" height=\"0\" scrolling=\"no\" frameborder=\"0\"></iframe>")
  end

  test "skips live_reload if not html request" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn(:get, "/")
           |> Plug.Conn.put_private(:phoenix_endpoint, Endpoint)
           |> put_resp_content_type("application/json")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "")
    refute to_string(conn.resp_body) |> String.contains?("<iframe src=\"/phoenix/live-reloader\" width=\"0\" height=\"0\" scrolling=\"no\" frameborder=\"0\"></iframe>")
  end
end
