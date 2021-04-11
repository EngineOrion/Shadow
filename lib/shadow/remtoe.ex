defmodule Shadow.Remote do
  use GenServer

  def start_link(key, ip, port) do
    GenServer.start_link(__MODULE__,  %{key: key, ip: ip, port: port}, name: name(key))
  end

  def init(params) do
    {:ok, socket} = :gen_tcp.connect(params.ip, params.port, [:binary, keepalive: true, nodelay: true])
    {:ok, Map.merge(params, %{socket: socket})}
  end

  def send(key, msg) do
    GenServer.cast(name(key), {:send, msg})
  end

  def handle_cast({:send, msg}, state) do
    #data = %{"id" => 1, "method" => "Responder.Status", "params" => [""]}
    :ok = :gen_tcp.send(state.socket, Jason.encode!(msg))
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, message}, state) do
    IO.inspect " - - - - - "
    IO.inspect message
    {:noreply, state}
  end

  defp name(key) do
    #{:via, Registry, key}
    key
  end
end
