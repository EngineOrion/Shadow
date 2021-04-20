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
  defstruct [:key, :ip, :port, :public, :socket]

  use GenServer

  alias Shadow.Routing
  alias Shadow.Routing.Message

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
    message = Message.process(data)
    case message.type do
      2 -> {:noreply, activate(message, state)}
    end
  end

  def handle_info({:tcp_closed, _socket}, _state) do
    Process.exit(self(), :normal)
  end

  # '{\"body\":{\"ip\":\"localhost\",\"key\":1234,\"port\":4242,\"public\":\"qwertzuiopü\"},\"timestamp\":6666,\"type\":2}'

  def activate(message, state) do
    # Activate in router
    routing = Routing.activate(state.key, message)
    %__MODULE__{
      key: routing.key,
      ip: message.ip,
      port: message.port,
      public: message.public,
      socket: state.socket
    }
  end
end
