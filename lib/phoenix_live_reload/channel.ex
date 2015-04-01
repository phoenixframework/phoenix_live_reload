defmodule Phoenix.LiveReload.Channel do
  use Phoenix.Channel

  @moduledoc """
  Phoenix's live-reload channel
  """

  def join("phoenix:live_reload", _msg, socket) do
    {:ok, _} = Application.ensure_all_started(:phoenix_live_reload)
    patterns = socket.endpoint.config(:live_reload)[:patterns]
    :fs.subscribe()

    {:ok, assign(socket, :patterns, patterns)}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, _event}}, socket) do
    if matches_any_pattern?(path, socket.assigns[:patterns]) do
      push socket, "assets_change", %{}
    end

    {:noreply, socket}
  end

  defp matches_any_pattern?(path, patterns) do
    Enum.any?(patterns, fn pattern -> String.match?(to_string(path), pattern) end)
  end
end
