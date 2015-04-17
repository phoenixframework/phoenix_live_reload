defmodule Phoenix.LiveReloader do
  use Phoenix.Router

  @moduledoc """
  Router for live-reload detection in development.

  ## Usage

  Add the `Phoenix.LiveReloader` plug within a `code_reloading?` block
  in your Endpoint, ie:

      if code_reloading? do
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

  """

  def call(%Plug.Conn{path_info: ["phoenix", "live_reload" | _]} = conn, opts) do
    conn
    |> super(opts)
    |> halt
  end

  def call(conn, _opts) do
    patterns = get_in conn.private.phoenix_endpoint.config(:live_reload), [:patterns]
    if patterns && patterns != [] do
      before_send_inject_reloader(conn)
    else
      conn
    end
  end

  socket "/phoenix/live_reload/listen" do
    channel "phoenix:live_reload", Phoenix.LiveReload.Channel
  end

  get "/phoenix/live_reload/frame", Phoenix.LiveReload.Frame, :frame

  defp before_send_inject_reloader(conn) do
    register_before_send conn, fn conn ->
      resp_body = to_string(conn.resp_body)

      if inject?(conn, resp_body) do
        [page | rest] = String.split(resp_body, "</body>")
        body = page <> reload_assets_tag() <> Enum.join(["</body>" | rest], "")

        put_in conn.resp_body, body
      else
        conn
      end
    end
  end

  defp inject?(conn, resp_body) do
    conn
    |> get_resp_header("content-type")
    |> html_content_type?
    |> Kernel.&&(String.contains?(resp_body, "<body"))
  end
  defp html_content_type?([]), do: false
  defp html_content_type?([type | _]), do: String.starts_with?(type, "text/html")

  defp reload_assets_tag() do
    """
    <iframe src="/phoenix/live_reload/frame" style="display: none;"></iframe>
    """
  end
end
