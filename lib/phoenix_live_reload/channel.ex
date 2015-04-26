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
      asset_type = Path.extname(path) |> String.lstrip(?.)

      push socket, "assets_change", %{asset_type: asset_type}
    end

    {:noreply, socket}
  end

  def matches_any_pattern?(path, patterns) do
    path = to_string(path)

    Enum.any?(patterns, fn pattern ->
      String.match?(path, pattern) and !String.match?(path, ~r/_build/)
    end)
  end
end
