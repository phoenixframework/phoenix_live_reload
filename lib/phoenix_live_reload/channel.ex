defmodule Phoenix.LiveReloader.Channel do
  @moduledoc """
  Phoenix's live-reload channel.
  """
  use Phoenix.Channel
  require Logger

  def join("phoenix:live_reload", _msg, socket) do
    {:ok, _} = Application.ensure_all_started(:phoenix_live_reload)
    patterns = socket.endpoint.config(:live_reload)[:patterns]

    if Process.whereis(:phoenix_live_reload_file_monitor) do
      FileSystem.subscribe(:phoenix_live_reload_file_monitor)
      {:ok, assign(socket, :patterns, patterns)}
    else
      {:error, %{message: "live reload backend not running"}}
    end
  end

  def handle_info({:file_event, _pid, {path, _event}}, socket) do
    if matches_any_pattern?(path, socket.assigns[:patterns]) do
      asset_type = remove_leading_dot(Path.extname(path))
      Logger.debug "Live reload: #{Path.relative_to_cwd(path)}"
      push socket, "assets_change", %{asset_type: asset_type}
    end

    {:noreply, socket}
  end

  defp matches_any_pattern?(path, patterns) do
    path = to_string(path)

    Enum.any?(patterns, fn pattern ->
      String.match?(path, pattern) and !String.match?(path, ~r{(^|/)_build/})
    end)
  end

  defp remove_leading_dot("." <> rest), do: rest
  defp remove_leading_dot(rest), do: rest
end
