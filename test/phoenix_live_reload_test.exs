defmodule PhoenixLiveReloadTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  setup do
    Logger.disable(self())
    :ok
  end

  defp conn(path) do
    conn(:get, path)
    |> Plug.Conn.put_private(:phoenix_endpoint, MyApp)
  end

  test "renders frame with phoenix.js" do
    conn = conn("/phoenix/live_reload/frame")
           |> Phoenix.LiveReloader.call([])

    assert conn.status == 200
    assert to_string(conn.resp_body) =~
           ~s[require("phoenix")]
    refute to_string(conn.resp_body) =~
           ~s[<iframe src="/phoenix/live_reload/frame"]
  end

  test "injects live_reload for html requests if configured and contains <body> tag" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "<html><body><h1>Phoenix</h1></body></html>")
    assert to_string(conn.resp_body) ==
      "<html><body><h1>Phoenix</h1><iframe src=\"/phoenix/live_reload/frame\" style=\"display: none;\"></iframe>\n</body></html>"
  end

  test "skips live_reload injection if html response missing body tag" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "<h1>Phoenix</h1>")
    assert to_string(conn.resp_body) == "<h1>Phoenix</h1>"
  end

  test "skips live_reload if not html request" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_resp_content_type("application/json")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "")
    refute to_string(conn.resp_body) =~
           ~s(<iframe src="/phoenix/live_reload/frame")
  end
end
