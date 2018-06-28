defmodule Phoenix.LiveReloader.Application do
  use Application

  require Logger

  def start(_type, _args) do
    import Supervisor.Spec
    children = [worker(__MODULE__, [])]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start_link do
    opts = [dirs: [Path.absname("")], name: :phoenix_live_reload_file_monitor]

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
        Logger.warn """
        Could not start Phoenix live-reload because we cannot listen to the file system.
        You don't need to worry! This is an optional feature used during development to
        refresh your browser when you save files and it does not affect production.
        """
        other
    end
  end
end
