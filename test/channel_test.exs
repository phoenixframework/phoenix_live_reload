defmodule Phoenix.LiveReloader.ChannelTest do
  use ExUnit.Case
  import Phoenix.ChannelTest

  alias Phoenix.LiveReloader
  alias Phoenix.LiveReloader.Channel

  @endpoint MyApp.Endpoint
  @moduletag :capture_log

  defp file_event(path, event) do
    {:file_event, self(), {path, event}}
  end

  setup do
    {:ok, _, socket} =
      LiveReloader.Socket |> socket() |> subscribe_and_join(Channel, "phoenix:live_reload", %{})

    {:ok, socket: socket}
  end

  test "sends a notification when asset is created", %{socket: socket} do
    send(socket.channel_pid, file_event("priv/static/phoenix_live_reload.js", :created))
    assert_push "assets_change", %{asset_type: "js"}
  end

  test "sends a notification when asset is removed", %{socket: socket} do
    send(socket.channel_pid, file_event("priv/static/long_gone.js", :removed))
    assert_push "assets_change", %{asset_type: "js"}
  end

  test "logs on live reload", %{socket: socket} do
    content =
      ExUnit.CaptureLog.capture_log(fn ->
        send(socket.channel_pid, file_event("priv/static/long_gone.js", :removed))
        assert_push "assets_change", %{asset_type: "js"}
      end)

    assert content =~ "[debug] Live reload: priv/static/long_gone.js"
  end

  test "does not send a notification when asset comes from _build", %{socket: socket} do
    send(
      socket.channel_pid,
      file_event(
        "_build/test/lib/phoenix_live_reload/priv/static/phoenix_live_reload.js",
        :created
      )
    )

    refute_receive _anything, 100
  end

  test "it allows project names containing _build", %{socket: socket} do
    send(
      socket.channel_pid,
      file_event(
        "/Users/auser/www/widget_builder/lib/live_web/templates/layout/app.html.eex",
        :created
      )
    )

    assert_push "assets_change", %{asset_type: "eex"}
  end

  test "sends notification for js", %{socket: socket} do
    send(socket.channel_pid, file_event("priv/static/phoenix_live_reload.js", :created))
    assert_push "assets_change", %{asset_type: "js"}
  end

  test "sends notification for css", %{socket: socket} do
    send(socket.channel_pid, file_event("priv/static/phoenix_live_reload.css", :created))
    assert_push "assets_change", %{asset_type: "css"}
  end

  test "sends notification for images", %{socket: socket} do
    send(socket.channel_pid, file_event("priv/static/phoenix_live_reload.png", :created))
    assert_push "assets_change", %{asset_type: "png"}
  end

  test "sends notification for templates", %{socket: socket} do
    send(socket.channel_pid, file_event("lib/live_web/templates/user/show.html.eex", :created))
    assert_push "assets_change", %{asset_type: "eex"}
  end

  test "sends notification for views", %{socket: socket} do
    send(socket.channel_pid, file_event('a/b/c/lib/live_web/views/user_view.ex', :created))
    assert_push "assets_change", %{asset_type: "ex"}
  end

  @endpoint MyApp.ReloadEndpoint
  test "sends notification for liveviews" do
    {:ok, _, socket} =
      LiveReloader.Socket |> socket() |> subscribe_and_join(Channel, "phoenix:live_reload", %{})
    socket.endpoint.subscribe("live_view")
    send(socket.channel_pid, file_event("lib/live_web/live/user_live.ex", :created))
    assert_receive {:phoenix_live_reload, :live_view, "lib/live_web/live/user_live.ex"}
  end
end
