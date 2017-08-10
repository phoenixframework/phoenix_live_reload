defmodule PhoenixLiveReload.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    opts = [dirs: [Path.absname("")], name: :phoenix_live_reload_file_monitor]
    Supervisor.start_link([worker(FileSystem, [opts])], strategy: :one_for_one)
  end
end
