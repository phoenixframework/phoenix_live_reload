defmodule Phoenix.LiveReloaderTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  setup do
    Logger.disable(self())
    :ok
  end

  defp conn(path) do
    conn(:get, path)
    |> Plug.Conn.put_private(:phoenix_endpoint, MyApp.Endpoint)
  end

  test "renders frame with phoenix.js" do
    conn = conn("/phoenix/live_reload/frame")
           |> Phoenix.LiveReloader.call([])

    assert conn.status == 200
    assert to_string(conn.resp_body) =~
           ~s[Phoenix.Socket]
    refute to_string(conn.resp_body) =~
           ~s[<iframe]

  end

  test "injects live_reload for html requests if configured and contains <body> tag" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "<html><body><h1>Phoenix</h1></body></html>")
    assert to_string(conn.resp_body) ==
      "<html><body><h1>Phoenix</h1><iframe src=\"/phoenix/live_reload/frame\" style=\"display: none;\"></iframe></body></html>"
  end

  test "injects live_reload with script_name" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_private(:phoenix_endpoint, MyApp.EndpointScript)
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "<html><body><h1>Phoenix</h1></body></html>")
    assert to_string(conn.resp_body) ==
      "<html><body><h1>Phoenix</h1><iframe src=\"/foo/bar/phoenix/live_reload/frame\" style=\"display: none;\"></iframe></body></html>"
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

  test "skips live_reload if body is nil" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_file(200, Path.join(File.cwd!, "README.md"))
    assert conn.status == 200
    refute to_string(conn.resp_body) =~
           ~s(<iframe src="/phoenix/live_reload/frame")
  end

  test "injects scoped live_reload with iframe class if configured" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_private(:phoenix_endpoint, MyApp.EndpointConfig)
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, "<html><body><h1>Phoenix</h1></body></html>")
    assert to_string(conn.resp_body) ==
      "<html><body><h1>Phoenix</h1><iframe src=\"/phoenix/live_reload/frame/foo/bar\" class=\"d-none\"></iframe></body></html>"
  end

  test "works with iolists as input" do
    opts = Phoenix.LiveReloader.init([])
    conn = conn("/")
           |> put_private(:phoenix_endpoint, MyApp.Endpoint)
           |> put_resp_content_type("text/html")
           |> Phoenix.LiveReloader.call(opts)
           |> send_resp(200, ["<html>", '<bo', [?d, ?y | ">"], "<h1>Phoenix</h1>", "</b", ?o, 'dy>', "</html>"])
    assert to_string(conn.resp_body) ==
      "<html><body><h1>Phoenix</h1><iframe src=\"/phoenix/live_reload/frame\" style=\"display: none;\"></iframe></body></html>"
  end
end
