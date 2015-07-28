defmodule Phoenix.LiveReload.Channel do
  @moduledoc """
  Phoenix's live-reload channel
  """

  use Phoenix.Channel
  alias Phoenix.LiveReload.Digest

  def join("phoenix:live_reload", _msg, socket) do
    {:ok, _} = Application.ensure_all_started(:phoenix_live_reload)
    patterns = socket.endpoint.config(:live_reload)[:patterns]
    :fs.subscribe()

    {:ok, assign(socket, :patterns, patterns)}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, _event}}, socket) do
    if matches_any_pattern?(path, socket.assigns[:patterns]) do
      asset_type = Path.extname(path) |> String.lstrip(?.)
      case File.read(path) do
        {:ok, source} ->
          new = :erlang.md5(source)
          old = Digest.get_and_update(path, new)

          if new != old do
            push socket, "assets_change", %{asset_type: asset_type}
          end
        {:error, _} ->
          Digest.delete(path)
          push socket, "assets_change", %{asset_type: asset_type}
      end
    end

    {:noreply, socket}
  end

  defp matches_any_pattern?(path, patterns) do
    path = to_string(path)

    Enum.any?(patterns, fn pattern ->
      String.match?(path, pattern) and !String.match?(path, ~r/_build/)
    end)
  end
end
