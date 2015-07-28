defmodule Phoenix.LiveReload do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    opts = [name: Phoenix.LiveReload.Supervisor, strategy: :one_for_one]
    Supervisor.start_link [worker(Phoenix.LiveReload.Digest, [])], opts
  end
end
