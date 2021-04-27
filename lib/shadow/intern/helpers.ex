defmodule Shadow.Intern.Helpers do
  @moduledoc """
  Global helper functions for simple tasks. Most of these functions
  were extracted out of single modules because they were needed
  somewhere else as well. This module should act as a dependency-less
  solution.
  """

  @doc """
  Get the current system time from DateTime and convert it to unix_time.
  """
  def unix_now() do
    DateTime.to_unix(DateTime.utc_now())
  end

  @doc """
  Get the local ip address of the own node.

  This function is simply a helper and will not be useable in the
  config, since there the global / public ip address will have to be
  used.
  """
  def ip_addr() do
    with {:ok, data} <- :inet.getif() do
      data |> Enum.at(0) |> elem(0) |> Tuple.to_list() |> Enum.join(".")
    else
      _ -> :error
    end
  end

  @doc """
  Fetches the port from the elixir config. (same rules as with
  ip_addr/0 apply).
  """
  def port() do
    Application.fetch_env!(:shadow, :port)
  end

  @doc """
  Generates a new (random) id mainly used by the Router & Member
  communication protocol.
  """
  def id() do
    time = unix_now() |> Integer.to_string(16)
    :crypto.hash(:md5, time) |> Base.url_encode64(padding: false)
  end
end
