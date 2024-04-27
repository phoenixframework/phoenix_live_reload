defmodule Phoenix.LiveReloader.WebConsoleLoggerInitializer do
  @moduledoc false

  use GenServer
  alias Phoenix.LiveReloader.WebConsoleLogger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    # We need to trap exits so that we receive the `terminate/2` callback during
    # a graceful shutdown
    Process.flag(:trap_exit, true)

    WebConsoleLogger.attach_logger()

    {:ok, opts}
  end

  @impl GenServer
  def terminate(_reason, state) do
    WebConsoleLogger.detach_logger()
    {:ok, state}
  end
end
