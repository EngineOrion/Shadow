defmodule Shadow.Listener do
  @moduledoc """

  Active process listening for new TCP connections. For each new conn
  a dedicated GenServer is started & ownership is transfered.

  Structure is simmilar to a GenServer & this process is started by
  the Application, but it is just a simple Task.

  Once a connection is found it is accepted, a new member is started &
  registered with the Router & Supervisor and ownership is transfered
  to that pid. 

  """

  @doc """
  Starts a new listening process on the given port. Should only be
  started once (should be autostarted by Application).
  """
  def start_link(port) do
    Task.start_link(__MODULE__, :accept, [port])
  end

  @doc """
  Starts a new listening process using erlang :gen_tcp and parameters.


  With the listening socket loop/1 is called, which becomes active on
  each incoming connection.

  """
  def accept(port) do
    {:ok, listen} =
      :gen_tcp.listen(
        port,
        [:binary, packet: :line, active: true, reuseaddr: true]
      )

    loop(listen)
  end

  @doc """

  Once a connection from the listening socket comes in it is accepted
  and a member is started. This happens in the Router, from where the
  Supervisor is called. Once the process is started, the ownership /
  control of the tcp_socket is transfered, so that new tcp_packets
  arrive at the member process, not the listener process.

  At the end the function calls itself again, so that new connections
  can be accepted.

  """
  def loop(listen) do
    {:ok, socket} = :gen_tcp.accept(listen)
    pid = Shadow.Routing.incoming(socket)
    :gen_tcp.controlling_process(socket, pid)
    loop(listen)
  end
end
