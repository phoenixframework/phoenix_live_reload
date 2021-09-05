defmodule Phoenix.LiveReloader.Channel do
  @moduledoc """
  Phoenix's live-reload channel.
  """
  use Phoenix.Channel
  alias Phoenix.LiveReloader.ChangeTracker
  require Logger

  def join("phoenix:live_reload", _msg, socket) do
    {:ok, _} = Application.ensure_all_started(:phoenix_live_reload)

    if Process.whereis(:phoenix_live_reload_file_monitor) do
      FileSystem.subscribe(:phoenix_live_reload_file_monitor)
      config = socket.endpoint.config(:live_reload)

      socket =
        socket
        |> assign(:patterns, config[:patterns] || [])
        |> assign(:debounce, config[:debounce] || 0)

      {:ok, socket}
    else
      {:error, %{message: "live reload backend not running"}}
    end
  end

  def handle_info({:file_event, _pid, {path, _event}}, socket) do
    %{patterns: patterns, debounce: debounce} = socket.assigns

    if matches_any_pattern?(path, patterns) do
      ext = Path.extname(path)

      for {path, ext} <- [{path, ext} | debounce(debounce, [ext], patterns)] do
        if ChangeTracker.put_new_hash(path) do
          asset_type = remove_leading_dot(ext)
          Logger.debug("Live reload: #{Path.relative_to_cwd(path)}")
          push(socket, "assets_change", %{asset_type: asset_type})
        end
      end
    end

    {:noreply, socket}
  end

  defp debounce(0, _exts, _patterns), do: []

  defp debounce(time, exts, patterns) when is_integer(time) and time > 0 do
    Process.send_after(self(), :debounced, time)
    debounce(exts, patterns)
  end

  defp debounce(exts, patterns) do
    receive do
      :debounced ->
        []

      {:file_event, _pid, {path, _event}} ->
        ext = Path.extname(path)

        if matches_any_pattern?(path, patterns) and ext not in exts do
          [{path, ext} | debounce([ext | exts], patterns)]
        else
          debounce(exts, patterns)
        end
    end
  end

  defp matches_any_pattern?(path, patterns) do
    path = to_string(path)

    Enum.any?(patterns, fn pattern ->
      String.match?(path, pattern) and not String.match?(path, ~r{(^|/)_build/})
    end)
  end

  defp remove_leading_dot("." <> rest), do: rest
  defp remove_leading_dot(rest), do: rest
end
