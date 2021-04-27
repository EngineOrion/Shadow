defmodule Shadow.Local.Socket do
  use GenServer

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

  def send(message) do
    GenServer.cast(:socket, {:send, message})
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
