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

  All live-reloading configuration must be done inside the `:live_reload`
  key of your endpoint, such as this:

      config :my_app, MyApp.Endpoint,
        ...
        live_reload: [
          patterns: [
            ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
            ~r{lib/my_app_web/views/.*(ex)$},
            ~r{lib/my_app_web/templates/.*(eex)$}
          ]
        ]

  The following options are supported:

    * `:patterns` - a list of patterns to trigger the live reloading.
      This option is required to enable any live reloading.

    * `:iframe_class` - a class to be used to be given to the iframe
      injected by live reload. By default the iframe uses a "style"
      attribute to hide itself but that can conflict with Content
      Security Policies. By giving a class, you disable the default
      style and control the styling of the iframe.

    * `:url` - the URL of the live reload socket connection. By default
      it will use the browser's host and port.

    * `:suffix` - if you are running live-reloading on an umbrella app,
      you may want to give a different suffix to each socket connection.
      You can do so with the `:suffix` option:

          live_reload: [
            suffix: "/proxied/app/path"
          ]

      And then configure the endpoint to use the same suffix:

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

  @html_before """
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

  def call(%Plug.Conn{path_info: ["phoenix", "live_reload", "frame" | _suffix]} = conn, _) do
    endpoint = conn.private.phoenix_endpoint
    config = endpoint.config(:live_reload)
    url = config[:url] || endpoint.path("/phoenix/live_reload/socket#{suffix(endpoint)}")
    interval = config[:interval] || 100

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, [
      @html_before,
      ~s[var socket = new Phoenix.Socket("#{url}");\n],
      ~s[var interval = #{interval};\n],
      @html_after
    ])
    |> halt()
  end

  def call(conn, _) do
    endpoint = conn.private.phoenix_endpoint
    config = endpoint.config(:live_reload)
    patterns = config[:patterns]

    if patterns && patterns != [] do
      before_send_inject_reloader(conn, endpoint, config)
    else
      conn
    end
  end

  defp before_send_inject_reloader(conn, endpoint, config) do
    register_before_send(conn, fn conn ->
      if conn.resp_body != nil and html?(conn) do
        resp_body = IO.iodata_to_binary(conn.resp_body)

        if has_body?(resp_body) and :code.is_loaded(endpoint) do
          [page | rest] = String.split(resp_body, "</body>")
          body = [page, reload_assets_tag(conn, endpoint, config), "</body>" | rest]
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

  defp reload_assets_tag(conn, endpoint, config) do
    path = conn.private.phoenix_endpoint.path("/phoenix/live_reload/frame#{suffix(endpoint)}")

    if class = config[:iframe_class] do
      ~s[<iframe src="#{path}" class="#{class}"></iframe>]
    else
      ~s[<iframe src="#{path}" style="display: none;"></iframe>]
    end
  end

  defp suffix(endpoint), do: endpoint.config(:live_reload)[:suffix] || ""
end
