defmodule Shadow.Local do
  @moduledoc """
  Module is the central interface for the local config & storage.
  
  TODO: Add safety!
  """

  alias Shadow.Routing.Member

  @doc """
  Generate the member file.
  """
  def generate() do
    routing = Shadow.Routing.export()
    config = Map.delete(read(), "containers")
    content = Jason.encode!(Map.merge(config, routing))
    File.write(member(), content)
  end

  def import(path) do
    member = File.read!(path) |> Jason.decode!
    server = Map.fetch!(member, "__SERVER__")
    key = Map.fetch!(server, "key")
    ip = Map.fetch!(server, "ip")
    port = Map.fetch!(server, "port")
    public = Map.fetch!(server, "public")
    m = %Member{key: key, ip: ip, port: port, public: public}
    Member.start_link({:out, m})
  end

  def is_local?(key) do
    locals = Map.fetch!(read(), "containers")
    with {:ok, _name} <- Map.fetch(locals, Integer.to_string(key)) do
      true
    else
      _ -> false
    end
  end

  def activation() do
    config = read()
    key = Map.fetch!(config, "key")
    ip = Map.fetch!(config, "ip")
    port = Map.fetch!(config, "port")
    public = Map.fetch!(config, "public")
    {key, ip, port, public}
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
