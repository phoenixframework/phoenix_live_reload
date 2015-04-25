defmodule Phoenix.LiveReload.Frame do
  import Plug.Conn

  @behaviour Plug
  @phoenix_js File.read!(Application.app_dir(:phoenix, "priv/static/phoenix.js"))
  @phoenix_live_reload_js File.read!(Application.app_dir(:phoenix_live_reload, "priv/static/phoenix_live_reload.js"))

  def init(opts) do
    opts
  end

  def call(conn, _) do
    config = conn.private.phoenix_endpoint.config(:live_reload)
    url    = Path.join(config[:url] || "/", "phoenix/live_reload/listen")

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, """
      <html><body>
      <script>
        #{@phoenix_js}

        var phx = require("phoenix")
        var socket = new phx.Socket("#{url}")

        #{@phoenix_live_reload_js}
      </script>
      </body></html>
    """)
  end
end
