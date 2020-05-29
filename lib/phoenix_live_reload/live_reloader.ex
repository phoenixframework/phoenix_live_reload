defmodule Phoenix.LiveReloader do
  @moduledoc """
  Router for live-reload detection in development.

  ## Usage

  Add the `Phoenix.LiveReloader` plug within a `code_reloading?` block
  in your Endpoint, ie:

      if code_reloading? do
        socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
        plug Phoenix.CodeReloader
        plug Phoenix.LiveReloader
      end

  ## Configuration

  For live-reloading in development, add the following `:live_reload`
  configuration to your Endpoint with a list of patterns to watch for changes:

      config :my_app, MyApp.Endpoint,
      ...
      live_reload: [
        patterns: [
          ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
          ~r{web/views/.*(ex)$},
          ~r{web/templates/.*(eex)$}
        ]
      ]


  By default the URL of the live-reload connection will use the browser's
  host and port. To override this, you can pass the `:url` option, ie:

      config :my_app, MyApp.Endpoint,
      ...
      live_reload: [
        url: "ws://localhost:4000",
        patterns: [
          ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
          ~r{web/views/.*(ex)$},
          ~r{web/templates/.*(eex)$}
        ]
      ]

  In case you have an umbrella app that runs different instances of live reload on proxied paths
  you can suffix the path to make them match properly. You can pass the `:suffix` option, ie:

      config :my_app, MyApp.Endpoint,
      ...
      live_reload: [
        suffix: "/proxied/app/path",
        patterns: [
          ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
          ~r{web/views/.*(ex)$},
          ~r{web/templates/.*(eex)$}
        ]
      ]

  You will also need to modify the socket path in `lib/myapp_web/endpoint.ex`:

      if code_reloading? do
        socket "/phoenix/live_reload/socket/proxied/app/path", Phoenix.LiveReloader.Socket
        ...
      end

  """

  import Plug.Conn
  @behaviour Plug

  phoenix_path = Application.app_dir(:phoenix, "priv/static/phoenix.js")
  reload_path = Application.app_dir(:phoenix_live_reload, "priv/static/phoenix_live_reload.js")
  @external_resource phoenix_path
  @external_resource reload_path

  @html_before  """
  <html><body>
  <script>
    #{File.read!(phoenix_path)}
  """

  @html_after """
    #{File.read!(reload_path)}
  </script>
  </body></html>
  """

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{path_info: ["phoenix", "live_reload", "frame" | _suffix]} = conn , _) do
    endpoint = conn.private.phoenix_endpoint
    config = endpoint.config(:live_reload)
    url = config[:url] || endpoint.path("/phoenix/live_reload/socket#{suffix(endpoint)}")
    interval = config[:interval] || 100

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, [
      @html_before,
      ~s[var socket = new Phoenix.Socket("], url, ~s[");\n],
      "var interval = ", interval, ";\n",
      @html_after
    ])
    |> halt()
  end

  def call(conn, _) do
    endpoint = conn.private.phoenix_endpoint
    patterns = get_in endpoint.config(:live_reload), [:patterns]
    if patterns && patterns != [] do
      before_send_inject_reloader(conn, endpoint)
    else
      conn
    end
  end

  defp before_send_inject_reloader(conn, endpoint) do
    register_before_send(conn, fn conn ->
      if conn.resp_body != nil and html?(conn) do
        resp_body = IO.iodata_to_binary(conn.resp_body)
        if has_body?(resp_body) and :code.is_loaded(endpoint) do
          [page | rest] = String.split(resp_body, "</body>")
          body = [page, reload_assets_tag(conn, endpoint), "</body>" | rest]
          put_in conn.resp_body, body
        else
          conn
        end
      else
        conn
      end
    end)
  end

  defp html?(conn) do
    case get_resp_header(conn, "content-type") do
      [] -> false
      [type | _] -> String.starts_with?(type, "text/html")
    end
  end

  defp has_body?(resp_body), do: String.contains?(resp_body, "<body")

  defp reload_assets_tag(conn, endpoint) do
    path = conn.private.phoenix_endpoint.path("/phoenix/live_reload/frame#{suffix(endpoint)}")
    [~S(<iframe src="), path, ~s(" style="display: none;"></iframe>\n)]
  end

  defp suffix(endpoint), do: endpoint.config(:live_reload)[:suffix] || ""
end
