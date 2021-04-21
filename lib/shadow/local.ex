defmodule Shadow.Local do
  @moduledoc """
  Module is the central interface for the local config & storage.
  
  TODO: Add safety!
  """

  @doc """
  Generate the member file.
  """
  def generate() do
    routing = Shadow.Routing.export()
    config = Map.delete(read(), "containers")
    content = Jason.encode!(Map.merge(config, routing))
    File.write(member(), content)
  end

  def is_local?(key) do
    locals = Map.fetch!(read(), "containers")
    with {:ok, _name} <- Map.fetch(locals, Integer.to_string(key)) do
      true
    else
      _ -> false
    end
  end

  def read() do
    File.read!(config()) |> Jason.decode!()
  end

  def config() do
    Application.fetch_env!(:shadow, :path) <> "config.json"
  end

  def member() do
    Application.fetch_env!(:shadow, :path) <> "member.json"
  end
end
