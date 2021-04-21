defmodule Shadow.Local do
  @moduledoc """
  Module is the central interface for the local config & storage.
  
  TODO: Add safety!

  """

  def read() do
    File.read!(config()) |> Jason.decode!()
  end

  def config() do
    Application.fetch_env!(:shadow, :path) <> "config.json"
  end

  def routing() do
    Application.fetch_env!(:shadow, :path) <> "routing.json"
  end
end
