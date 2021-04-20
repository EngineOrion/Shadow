defmodule Shadow.Routing.Member do
  @moduledoc """
  Active process for each connected & available member of the cluster.

  This object (struc) will also be stored by the routing table
  process, "ref" is a monitoring reference to the process.

  Type: 
  - in: (incoming) Connection held by this node (listener).
  - out: (outgoing) Outgoing connection to another node.

  Both types use the :gen_tcp module, therefor the structure is alike.
  
  Active: Only after public, key & other values have been established
  (handshake) can the connection be used.

  """
  @derive Jason.Encoder
  defstruct [:key, :ip, :port, :score, :public, :timestamp, :ref, :socket, :active]

  use GenServer

  @doc """
  Entry point for starting a new process => Creating a new connection.
  The type (:in / :out) is passed as a variable, since two differend
  inits will be called from that.
  """
  def start_link({type, %__MODULE__{} = params}) do
    GenServer.start_link(__MODULE__, {type, params})
  end

  def init({:out, %__MODULE__{} = params}) do
    with {:ok, socket} <- :gen_tcp.connect(params.ip, params.port, [:binary, keepalive: true, nodelay: true]) do
      member = Map.put(params, :socket, socket)
      {:ok, member}
    else
      _ -> {:error, "Connection refused"}
    end
  end

  def init({:in, %__MODULE__{} = params}) do
    {:ok, params}
  end

  # GenServer Interface
  def send(pid, data) do
    GenServer.cast(pid, {:send, data})
  end

  # GenServer Callbacks
  def handle_cast({:send, data}, %{socket: socket} = state) do
    :gen_tcp.send(socket, data)
    {:noreply, state}
  end

  # TCP Callbacks
  def handle_info({:tcp, _socket, data}, state) do
    # TODO: Pass to router
    #with {:ok, message} <- Jason.decode(String.trim(data)) do
    IO.inspect data
    {:noreply, state}
    #end
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    IO.puts "shutdown"
    Process.exit(self(), :shutdown)
  end
end
