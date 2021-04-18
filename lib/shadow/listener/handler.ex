defmodule Shadow.Listener.Handler do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(socket) do
    {:ok, %{socket: socket, messages: []}}
  end

  def send(pid, data) do
    GenServer.cast(pid, {:send, data})
  end

  def handle_info({:tcp, _socket, data}, state) do
    state = process_data(data, state)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Process.exit(self(), :normal)
  end

  def handle_cast({:send, data}, %{socket: socket} = state) do
    :gen_tcp.send(socket, data)
    {:noreply, state}
  end

  defp process_data(data, state) do
    IO.puts data
    %{socket: state.socket, messages: state.messages ++ [data]}
  end
end
