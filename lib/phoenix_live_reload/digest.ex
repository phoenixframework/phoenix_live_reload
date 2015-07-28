defmodule Phoenix.LiveReload.Digest do
  @moduledoc false
  @name __MODULE__

  def start_link do
    Agent.start_link(fn -> HashDict.new end, name: @name)
  end

  def get_and_update(path, new) do
    Agent.get_and_update(@name, fn state ->
      {HashDict.get(state, path), HashDict.put(state, path, new)}
    end)
  end

  def delete(path) do
    Agent.update(@name, &HashDict.delete(&1, path))
  end

  def clear do
    Agent.update(@name, fn _ -> HashDict.new end)
  end
end
