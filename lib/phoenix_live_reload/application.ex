defmodule Phoenix.LiveReloader.Application do
  use Application
  require Logger

  alias Phoenix.LiveReloader.WebConsoleLogger

  def start(_type, _args) do
    # note we always attach and start the logger as :phoenix_live_reload should only
    # be started in dev via user's `only: :dev` entry.
    WebConsoleLogger.attach_logger()

    children = [
      WebConsoleLogger,
      %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start_link do
    dirs = Application.get_env(:phoenix_live_reload, :dirs, [""])
    backend_opts = Application.get_env(:phoenix_live_reload, :backend_opts, [])

    opts =
      [
        name: :phoenix_live_reload_file_monitor,
        dirs: Enum.map(dirs, &Path.absname/1)
      ] ++ backend_opts

    opts =
      if backend = Application.get_env(:phoenix_live_reload, :backend) do
        [backend: backend] ++ opts
      else
        opts
      end

    case FileSystem.start_link(opts) do
      {:ok, pid} ->
        {:ok, pid}

      other ->
        Logger.warning("""
        Could not start Phoenix live-reload because we cannot listen to the file system.
        You don't need to worry! This is an optional feature used during development to
        refresh your browser when you save files and it does not affect production.
        """)

        other
    end
  end
end
