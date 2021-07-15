defmodule Phoenix.LiveReloader.Frame do
  phoenix_path = Application.app_dir(:phoenix, "priv/static/phoenix.js")
  reload_path = Application.app_dir(:phoenix_live_reload, "priv/static/phoenix_live_reload.js")
  @external_resource phoenix_path
  @external_resource reload_path

  @phoenix_js File.read!(phoenix_path) |> String.replace("//# sourceMappingURL=", "// ")
  @phoenix_reload_js File.read!(reload_path)

  defmacro phoenix_js do
    @phoenix_js
  end

  defmacro content(url, interval, target_window) do
    quote do
      [
        "<html><body>",
        unquote(script_tag()),
        ~s[var socket = new Phoenix.Socket("#{unquote(url)}");\n],
        ~s[var interval = #{unquote(interval)};\n],
        ~s[var targetWindow = "#{unquote(target_window)}";\n],
        unquote(@phoenix_reload_js),
        "</script></body></html>"
      ]
    end
  end

  defp script_tag do
    if esm_module?(@phoenix_js) do
      """
      <script type="module">
      import * as Phoenix from './js/phoenix.js';
      """
    else
      """
      <script>
      #{@phoenix_js}
      """
    end
  end

  defp esm_module?(js) do
    Regex.match?(~r/[^\w]export[^\w]/, js)
  end
end
