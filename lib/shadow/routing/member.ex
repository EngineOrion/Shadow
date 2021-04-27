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

  @typedoc """
  Each Member state only holds a single %Member{} struct. In there all
  relevant data will be stored. 

  Naming: 
  - Key: Shadow ID / IP System for addressing nodes & containers.
  - Public: Public RSA "Key", currenlty unused, integrate with crypto
    module later.

  TODO: Expand fields with message log (memory only) (for admin /
  debug purposes).
  """
  @derive Jason.Encoder
  defstruct [:id, :key, :ip, :port, :public, :socket]

  use GenServer

  alias Shadow.Routing
  alias Shadow.Routing.Message

  @doc """
  Entry point for starting a new process => Creating a new connection.
  The type (:in / :out) is passed as a variable, since two differend
  inits will be called from that.
  """
  def start_link({type, %__MODULE__{} = params}) do
    GenServer.start_link(__MODULE__, {type, params}, name: name(params.id))
  end

  #  - - - - - - Interface - - - - - - 
  
  @doc """
  Send a message to the remote node using the socket.

  Warning: Message needs to be encoded / binary.
  """
  def send(id, message) do
    GenServer.cast(name(id), {:send, message})
  end

  @doc """
  Returns the entire state of the member for the routing table export.
  """
  def export(id) do
    GenServer.call(name(id), :export)
  end

  @doc """ 
  Function for activating the member in the router & updating the
  local state with the new data. It takes in the activation message
  from the remote node, calls to update the router and than returns a
  new state. 

  This function should not usually be called externaly, since it
  requires the state of the member process. Instead it should get
  called by a handle_* function. 
  """
  def activate(message, state) do
    routing = Routing.activate(state.id, message)
    %__MODULE__{
      id: routing.id,
      key: routing.key,
      ip: message.ip,
      port: message.port,
      public: message.public,
      socket: state.socket
    }
  end

  @doc """
  Easy helper for switching the active flag in the routing table.
  Since it will also be called in a handle_* it returns the original
  state again.
  """
  def confirm(state) do
    :ok = Routing.switch(state.id)
    state
  end

  #  - - - - - - Callbacks - - - - - - 

  @doc """
  For outgoing connections the :gen_tcp socket is initialized in the
  init function. By this time it will already be part of the router,
  therefor it can be started on its own.
  
  Starting with :in simply passes on the state, since all objects were
  already initialized in the router.
  """
  def init({:out, %__MODULE__{} = params}) do
    with {:ok, socket} <-
           :gen_tcp.connect(params.ip, params.port, [:binary, keepalive: true, nodelay: true]) do
      member = Map.put(params, :socket, socket)
      {:ok, member}
    else
      _ -> {:error, "Connection refused"}
    end
  end

  def init({:in, %__MODULE__{} = params}) do
    {:ok, params}
  end

  @doc """
  Takes in a message (currenlty has to be a string / binary) and
  executes :gen_tcp.send with the state socket. The message has to be
  encoded as json in the caller.
  """
  def handle_cast({:send, data}, state) do
    :gen_tcp.send(state.socket, data)
    {:noreply, state}
  end

  @doc """
  Returns the entire state, which should be used in the routing table
  export function.
  """
  def handle_call(:export, _from, state) do
    {:reply, state, state}
  end

  # - - - - - - TCP - - - - - - 

  @doc """
  The central entry point for incoming :tcp messages. From here any
  messages will get processed by Message.process/1.
  
  Messages will land here because ownership was transfered to this
  process. 
  """

  def handle_info({:tcp, _socket, data}, state) do
  message = Message.process(data)

    case message.type do
      0 -> {:noreply, call(message)}
      2 -> {:noreply, activate(message, state)}
      3 -> {:noreply, confirm(state)}
    end
  end

  @doc """

  If a process shuts down (for whatever reason) the member process
  will also stop.

  In the future at this point the message log should be written into a
  log / temp file.
  """
  def handle_info({:tcp_closed, _socket}, _state) do
    Process.exit(self(), :normal)
  end

  #  - - - - - - HELPER - - - - - - 
  
  defp name(id) do
    {:via, Shadow.Intern.Registry, id}
  end
end
