defmodule Phoenix.LiveReload.Frame do
  import Plug.Conn

  @behaviour Plug

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
        #{phoenix_js()}
        var phx = require("phoenix")
        var socket = new phx.Socket("#{url}")
        socket.connect()
        socket.join("phoenix:live_reload", {})
          .receive("ok", function(chan){
            chan.on("assets_change", function(msg){
              chan.off("assets_change")
              window.top.location.reload()
            })
          })
      </script>
      </body></html>
    """)
  end

  defp phoenix_js() do
    File.read! Application.app_dir(:phoenix, "priv/static/phoenix.js")
  end
end
