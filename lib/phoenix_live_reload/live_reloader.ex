#
# Patch this file to enable HMR; Hot Module Reloading for other asset types
#

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

    * `:script_attrs` - HACK attrs to be given to the script injected by
      live reload. Expects a keyword list of atom keys and string values.

    * `:notify` - a keyword list of topics pointing to a list of patterns.
      A message of the form `{:phoenix_live_reload, topic, path}` will be
      broadcast on the topic whenever file in the list of patterns changes.

    * `:debounce` - an integer in milliseconds to wait before sending
      live reload events to the browser. Defaults to `0`.

    * `:target_window` - the window that will be reloaded, as an atom.
      Valid values are `:top` and `:parent`. Defaults to `:parent`.

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

    * `:root` - HACK Specifies root directory of static files.
      This part is trimmed from modified file paths and sent in
      `assets_change` WebSocket frame.

    * `:reload_page_on_css_changes` - If true, CSS changes will trigger a full
      page reload like other asset types instead of the default hot reload.
      Useful when class names are determined at runtime, for example when
      working with CSS modules. Defaults to false.

    * `:web_console_logger` - If true, the live reloader will log messages
      to the web console in your browser. Defaults to false.
      *Note*: Requires Elixir v1.15+ and your application javascript bundle will need
      to enable logs. See the README for more information.

  In an umbrella app, if you want to enable live reloading based on code
  changes in sibling applications, set the `reloadable_apps` option on your
  endpoint to ensure the code will be recompiled, then add the dirs to
  `:phoenix_live_reload` to trigger page reloads:

      # in config/dev.exs
      root_path =
        __ENV__.file
        |> Path.dirname()
        |> Path.join("..")
        |> Path.expand()

      config :phoenix_live_reload, :dirs, [
        Path.join([root_path, "apps", "app1"]),
        Path.join([root_path, "apps", "app2"]),
      ]

  You'll also want to be sure that the configured `:patterns` for
  `live_reload` will match files in the sibling application.
  """

  import Plug.Conn
  @behaviour Plug

  phoenix_path = Application.app_dir(:phoenix, "priv/static/phoenix.js")
  reload_path = Application.app_dir(:phoenix_live_reload, "priv/static/phoenix_live_reload.js")
  @external_resource phoenix_path
  @external_resource reload_path

  # HACK Patching below to insert reload script as <script> in <head> rather than <iframe> in <body>
  # since <iframe> in <body> sometimes breaks Elm's virtual DOM after HMR happened!
  @script_before """
  #{File.read!(phoenix_path)}
  """

  @script_after """
  #{File.read!(reload_path)}
  """

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{path_info: ["phoenix", "live_reload", "frame" | _suffix]} = conn, _) do
    endpoint = conn.private.phoenix_endpoint
    config = endpoint.config(:live_reload)
    url = config[:url] || endpoint.path("/phoenix/live_reload/socket#{suffix(endpoint)}")
    interval = config[:interval] || 100
    target_window = get_target_window(config[:target_window] || :parent)
    reload_page_on_css_changes? = config[:reload_page_on_css_changes] || false

    conn
    |> put_resp_content_type("text/javascript")
    |> send_resp(200, [
      @script_before,
      ~s[var socket = new Phoenix.Socket("#{url}");\n],
      ~s[var interval = #{interval};\n],
      ~s[var targetWindow = "#{target_window}";\n],
      ~s[var reloadPageOnCssChanges = #{reload_page_on_css_changes?};\n],
      @script_after
    ])
    |> halt()
  end

  def call(conn, _) do
    endpoint = conn.private.phoenix_endpoint
    config = endpoint.config(:live_reload)

    if match?([_ | _], config[:patterns]) || config[:web_console_logger] do
      conn
      |> put_private(:phoenix_live_reload, true)
      |> before_send_inject_reloader(endpoint, config)
    else
      conn
    end
  end

  defp before_send_inject_reloader(conn, endpoint, config) do
    register_before_send(conn, fn conn ->
      if conn.resp_body != nil and html?(conn) do
        resp_body = IO.iodata_to_binary(conn.resp_body)

        if has_head?(resp_body) and :code.is_loaded(endpoint) do
          [head | rest] = String.split(resp_body, "</head>")
          body = [head, reload_assets_tag(conn, endpoint, config), "</head>" | rest]
          put_in(conn.resp_body, body)
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

  defp has_head?(resp_body), do: String.contains?(resp_body, "<head")

  defp reload_assets_tag(conn, endpoint, config) do
    path = conn.private.phoenix_endpoint.path("/phoenix/live_reload/frame#{suffix(endpoint)}")
    attrs = Keyword.merge([src: path], config[:script_attrs] || [])
    IO.iodata_to_binary(["<script", attrs(attrs), "></script>"])
  end

  defp attrs(attrs) do
    Enum.map(attrs, fn
      {_key, nil} -> []
      {_key, false} -> []
      {key, true} -> [?\s, key(key)]
      {key, value} -> [?\s, key(key), ?=, ?", value(value), ?"]
    end)
  end

  defp key(key) do
    key
    |> to_string()
    |> String.replace("_", "-")
    |> Plug.HTML.html_escape_to_iodata()
  end

  defp value(value) do
    value
    |> to_string()
    |> Plug.HTML.html_escape_to_iodata()
  end

  defp suffix(endpoint), do: endpoint.config(:live_reload)[:suffix] || ""

  defp get_target_window(:parent), do: "parent"

  defp get_target_window(_), do: "top"
end
