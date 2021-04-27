defmodule Shadow.Local.Portal do
  @moduledoc """
  Responsible for interfacing with the orion unix socket.

  TODO: Implement unix socket interface.
  """

  use GenServer

  @doc """
  Currenlty messages for a local container are just printed out.
  """
  def send(message) do
    IO.puts(message)
    :ok
  end
end
