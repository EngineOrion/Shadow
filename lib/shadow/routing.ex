defmodule Shadow.Routing do
  @moduledoc """
  Core decision unit of the Shadow-System. The routing system is
  responsible for determining where packets should be sent, as well as
  supervising all connected members.

  In a future version of the Shadow System this module should be
  merged / converted into an Elixir Supervisor, since it already
  fulfills some of its functions. While this would introduce a third
  supervisor into the codebase, the actual file wouldn't have to
  change a lot, since it mostly relies on GenServer callbacks.

  Struct:
  This struct is similiar to %Member{}, but with some different
  fields. Since the Router does not have to know about sockets and the
  Member does not have to know about the reference this split is not


  Since before the activation the "Key" is unknown the ID is used as a
  node-unique ID. It will not be exported or persisted, but is simply
  used as an internal value.

  The timestamp is currently unused, but will influence updates in the
  routing table later.

  The active flag is used to determine whether a Member has been
  activated and is authorized to receive messages.
  """

  use GenServer

  alias Shadow.Local
  alias Shadow.Intern.Supervisor
  alias Shadow.Routing.Member
  alias Shadow.Routing.Key
  alias Shadow.Intern.Helpers

  defstruct [:id, :key, :active, :ref, :timestamp]

  @doc """
  Starts a new Routing process. Each node can only have one, since its
  name is hard coded. The initial state is irrelevant since it will be
  build dynamically later.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :routing)
  end

  def init(_) do
    {:ok, %{}}
  end

  @doc """
  Creates a non active process, with state for both the new process
  state & updated routing table. Temporary Key: Passed to the Member
  Process until it is active.
  """
  def incoming(socket) do
    GenServer.call(:routing, {:in, socket})
  end

  @doc """
  Creates a non active process and updates the routing table. Used for
  outgoing processes, where no socket, but the target IP & Port are
  available.
  """
  def outgoing({key, ip, port, public}) do
    GenServer.call(:routing, {:out, {key, ip, port, public}})
  end

  @doc """
  If the member receives an activation message (Type 2) this function
  gets called to both update the routing entry and the Member process
  with the newest information.

  This function is ACTIVE and will send a confirmation (Type 3) to the
  remote Member.
  """
  def activate(id, message) do
    GenServer.call(:routing, {:activate, id, message})
  end

  @doc """
  Finds the nearest member node for a new (outgoing) message. This
  uses the Kademlia Routing Algorithm and XOR to find the optimal
  target. If the target is a locally running container, the target
  value will be __SERVER__.
  """
  def target(message) do
    GenServer.call(:routing, {:target, message})
  end

  @doc """

  Takes in a target (object, not key) and a message. Then sends the
  message to the node.

  TODO: Unify input types, make all objects or all ids.
  If the target is __SERVER__, the local module is used.
  """
  def send(target, message) do
    if target == :__SERVER__ do
      Local.Portal.send(message)
    else
      Member.message(target.id, message)
    end
  end

  @doc """
  If the node has received an activation confirmation (Type 3) the
  active flag simply needs to be switched.

  This function is PASSIV.
  """
  def switch(id) do
    GenServer.cast(:routing, {:switch, id})
  end

  def handle_call({:in, socket}, _from, state) do
    id = Helpers.id()
    member = %Member{id: id, socket: socket}
    routing = %__MODULE__{id: id, active: false, timestamp: Helpers.unix_now()}

    with {:ok, pid} <- Supervisor.start_in(member) do
      ref = Process.monitor(pid)
      full = Map.put(routing, :ref, ref)
      new = Map.put(state, id, full)
      {:reply, pid, new}
    else
      _ -> {:reply, {:error, "Routing failed!"}, state}
    end
  end

  def handle_call({:out, {key, ip, port, public}}, _from, state) do
    id = Helpers.id()
    member = %Member{id: id, key: key, ip: ip, port: port, public: public}
    routing = %__MODULE__{id: id, key: key, active: false, timestamp: Helpers.unix_now()}

    with {:ok, pid} <- Supervisor.start_out(member) do
      {lkey, lip, lport, lpublic} = Local.activation()

      message =
        %{
          type: 2,
          timestamp: Helpers.unix_now(),
          body: %{key: lkey, ip: lip, port: lport, public: lpublic}
        }
        |> Jason.encode!()

      :ok = Member.send(id, message <> "\n")
      ref = Process.monitor(pid)
      full = Map.put(routing, :ref, ref)
      new = Map.put(state, id, full)

      {:reply, pid, new}
    else
      _ -> {:reply, {:error, "Routing failed!"}, state}
    end
  end

  def handle_call({:activate, id, message}, _from, state) do
    member = Map.get(state, id)

    if not member.active do
      updated = %__MODULE__{
        id: id,
        key: message.body.key,
        ref: member.ref,
        timestamp: member.timestamp,
        active: true
      }

      cleared = Map.pop(state, id) |> elem(1)
      new = Map.put(cleared, id, updated)
      confirmation = %{type: 3, timestamp: Helpers.unix_now()} |> Jason.encode!()
      :ok = Member.send(member.id, confirmation <> "\n")
      {:reply, updated, new}
    else
      {:reply, member, state}
    end
  end

  def handle_call({:target, message}, _from, state) do
    if Local.is_local?(message.target) do
      {:reply, :__SERVER__, state}
    else
      if Enum.count(state) == 0 do
        {:reply, :__SERVER__, state}
      else
	IO.inspect state

	distanced = Enum.map(state, fn {_k, v} ->
	  IO.inspect v
	  Key.distance(message.target, v.key)
	end)
	
        min = Enum.min(distanced)
        member = Enum.find(state, fn {_k, v} -> min == Key.distance(message.target, v.key) end)
        {:reply, elem(member, 1), state}
      end
    end
  end

  def handle_cast({:switch, id}, state) do
    member = Map.get(state, id)
    updated = Map.put(member, :active, true)
    {:noreply, Map.put(state, id, updated)}
  end

  def handle_info({:DOWN, ref, _, _, _}, state) do
    item = get_key(state, ref)
    new = Map.pop(state, item.id, state) |> elem(1)
    {:noreply, new}
  end

  defp get_key(state, ref) do
    Enum.find(state, fn {_k, v} -> v.ref == ref end) |> elem(1)
  end
end
