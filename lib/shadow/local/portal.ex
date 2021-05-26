defmodule Shadow.Local.Portal do
  @moduledoc """
  Responsible for interfacing with the orion unix socket.
  """

  use GenServer

  alias Shadow.Local
  alias Shadow.Routing.Message

  def start_link(_params) do
    GenServer.start_link(__MODULE__, :ok, name: :portal)
  end

  def send(message) do
    GenServer.cast(:portal, {:send, message})
  end

  def init(_params) do
    path = Local.path() <> "shadow.sock"
    {:ok, socket} = :gen_tcp.connect({:local, path}, 0, [:binary])
    {:ok, socket}
  end

  def handle_cast({:send, message}, state) do
    :gen_tcp.send(state, message)
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    message = Message.process(data)
    Shadow.send(message)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Process.exit(self(), :normal)
  end
end
