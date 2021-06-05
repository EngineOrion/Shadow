defmodule Shadow.Local do
  @moduledoc """
  Module is the interface for the local config & storage.

  It handles reading & writing to the local file system, as well as
  interfacing with the config.
  """

  require Logger

  @doc """
  Fetches the local routing table & __SERVER__ config and writes it to
  a public member file. It removes the "containers" section and
  encodes everything in json.
  """
  def generate() do
    with {:ok, body} <- Jason.encode(Map.replace(%{"__SERVER__" => read()}, "ip", Shadow.Intern.Helpers.ip_addr())) do
      File.write(member(), body)
    else
      _ -> failed()
    end
  end

  defp failed() do
    Logger.info("Local config error, recheck __SERVER__ config!")
    :error
  end

  @doc """
  Imports a member file from a different node in order to add it to
  the active connections.
  """
  def import(path) do
    with {:ok, file} <- File.read(path),
         {:ok, member} <- Jason.decode(file),
         {:ok, server} <- Map.fetch(member, "__SERVER__"),
         {:ok, key} <- Map.fetch(server, "key"),
         {:ok, ip} <- Map.fetch(server, "ip"),
         {:ok, port} <- Map.fetch(server, "port"),
         {:ok, public} <- Map.fetch(server, "public") do
      Shadow.Routing.outgoing({key, ip, port, public})
    else
      _ -> failed()
    end
  end

  @doc """
  Fetches the local config & containers stored there. If the provided
  key is part of the config true is returned. Otherwise the key is
  from a foreign node and false is returned.
  """
  def is_local?(key) do
    {local, 0} = System.cmd("hunter", ["get", "key", Integer.to_string(key)])
    if String.length(local) > 3 do
      true
    else
      false
    end
  end

  @doc """
  Specific reader for fetching all required fields for an activation
  (Type 2). Returns them as a 4 part tuple:
  """
  def activation() do
    server = read()
    with {:ok, key} <- Map.fetch(server, "key"),
	 {:ok, ip} <- Map.fetch(server, "ip"),
	 {:ok, port} <- Map.fetch(server, "port"),
	 {:ok, public} <- Map.fetch(server, "public")
      do
      {key, ip, port, public}
      else
	_ -> {:error, "Config Invalid!"}
    end
  end

  @doc """
  Currently not typesafe, uses toe hunter cli to fetch the stored config.
  
  If the local config is not valid, the entire application will not
  start properly, therefor type safety is not required.
  """
  def read() do
    {c, 0} = System.cmd("hunter", ["get", "config"])
    with {:ok, config} <- Jason.decode(c) do
      Map.fetch!(config, "sources") |> Enum.filter(fn x -> Map.fetch!(x, "name") == "shadow" end) |> Enum.at(0)
    else
      # Warning: No real type safety. Application can't run without valid config!
      _ -> failed()
    end
  end

  @doc """
  Fetches the path value from the Elixir config & appends "config.json", not type safe.
  Issues:
  - Safety: Without valid config (both elixir & orion) the application will fail.
  - Hard coded names: Currenlty it is not possible to change the name of the config or other files.
  """
  def config() do
    path() <> "config.json"
  end

  @doc """
  Like config/0 but will append "member.json" instead of
  "config.json". This file will be used to store the local member
  file.
  """
  def member() do
    path() <> "member.json"
  end

  @doc """
  Gets the path of the config directory from the ex-config.
  """
  def path() do
    Application.fetch_env!(:shadow, :path)
  end
end
