defmodule Shadow.Listener do
  @moduledoc """
  Active process listening for new TCP connections. 
  For each new conn a dedicated GenServer is started & ownership is transfered.
  """

  def start_link(port) do
    Task.start_link(__MODULE__, :accept, [port])
  end

  def accept(port) do
    {:ok, listen_socket} = :gen_tcp.listen(
      port,
      [:binary, packet: :line, active: :true, reuseaddr: true]
    )
    loop_acceptor(listen_socket)
  end

  defp loop_acceptor(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    # TODO: Call routing for new processes, not supervisor directly.
    pid = Shadow.Routing.incoming(socket)
    :gen_tcp.controlling_process(socket, pid)
    loop_acceptor(listen_socket)
  end
end
