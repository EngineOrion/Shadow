defmodule Shadow.Listener do
  @moduledoc """
  (http://www.robgolding.com/blog/2019/05/21/tcp-genserver-elixir/)
  """

  alias Shadow.DynamicHandler, as: Supervisor

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
    {:ok, pid} = Supervisor.start_child(socket)
    :gen_tcp.controlling_process(socket, pid)
    loop_acceptor(listen_socket)
  end
end
