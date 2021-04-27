defmodule Shadow.Local.Portal do
  @moduledoc """
  Responsible for interfacing with the orion unix socket.

  TODO: Remove hard coded path.
  """

  use GenServer

  @doc """
  Currenlty messages for a local container are just printed out.
  """
  def send(message) do
    IO.puts(message)
    :ok
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :socket)
  end

  def init(_) do
    {:ok, socket} =
      :gen_tcp.connect({:local, "/home/jeykey/Downloads/shadow/.orion/orion.sock"}, 0, [
        :binary,
        active: false,
        reuseaddr: true
      ])

    {:ok, socket}
  end

  def handle_cast({:send, message}, socket) do
    :gen_tcp.send(socket, message)
    {:noreply, socket}
  end

  def handle_info({:tcp, _socket, data}, socket) do
    IO.puts(data)
    {:noreply, socket}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Process.exit(self(), :normal)
  end
end
