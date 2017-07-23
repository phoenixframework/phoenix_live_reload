defmodule PhoenixLiveReload.Application do
  def start(_type, _args) do
    FileSystem.start_link(dirs: [Path.absname("")], name: :pnx_live_reload_file_monitor)
    {:ok, self()}
  end
end
