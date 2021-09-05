defmodule Phoenix.LiveReloader.ChangeTracker do
  @moduledoc """
  Keeps track of the SHA-1 hashes of the watched files. This is used to only
  emit change events when the given files have changed, rather than simply when
  they're written to the file system.

  This is to avoid unnecessary browser refreshes.
  """
  use GenServer

  @table_name __MODULE__.ETS

  @doc false
  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @doc """
  Calculates a checksum on the given file and returns `true` if a change was
  detected; otherwise `false`.
  """
  def put_new_hash(path) do
    hash =
      case File.read(path) do
        {:ok, content} -> :crypto.hash(:sha, content)
        _ -> nil
      end

    if is_nil(hash) do
      delete_hash(path)
    end

    if current_stored_hash(path) == hash do
      false
    else
      put_hash(path, hash)
      true
    end
  end

  @doc false
  def current_stored_hash(path) do
    case :ets.lookup(@table_name, path) do
      [{_, hash} | _] -> hash
      _ -> nil
    end
  end

  @doc false
  def put_hash(path, hash) do
    case current_stored_hash(path) do
      ^hash -> :ok
      _ -> :ets.insert(@table_name, {path, hash})
    end
  end

  @doc false
  def delete_hash(path) do
    :ets.delete(@table_name, path)
  end

  @impl true
  def init(_arg) do
    table = :ets.new(@table_name, [:public, :named_table, read_concurrency: true])
    {:ok, {table, %{}}}
  end
end
