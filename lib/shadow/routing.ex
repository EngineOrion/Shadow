defmodule Shadow.Routing do
  @moduledoc """

  Core decision unit of the Shadow-System. The routing system is
  responsible for determining where packets should be sent, as well as
  supervising the possible targets.
  """

  use GenServer

  alias Shadow.Local
  alias Shadow.Intern.Supervisor
  alias Shadow.Routing.Member
  alias Shadow.Routing.Key
  alias Shadow.Intern.Helpers

  defstruct [:id, :key, :active, :ref, :timestamp]

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
  def new(socket) do
    GenServer.call(:routing, {:new, socket})
  end

  def activate(key, message) do
    GenServer.call(:routing, {:activate, key, message})
  end

  def target(message) do
   GenServer.call(:routing, {:target, message}) 
  end

  def send(target, message) do
    if target == :__SERVER__ do
      Local.Portal.send(message)
    else
      Member.send(target.id, message)
    end
  end

  def export() do
    GenServer.call(:routing, :export)
  end

  def handle_call({:new, socket}, _from, state) do
    id = Helpers.id()
    member = %Member{id: id, socket: socket}
    routing = %__MODULE__{id: id, active: false, timestamp: Helpers.unix_now()}
    with {:ok, pid} <- Supervisor.start_child(member) do
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
	key: message.key,
	ref: member.ref,
	timestamp: member.timestamp,
	active: true
      }
      cleared = Map.pop(state, id) |> elem(1)
      new = Map.put(cleared, id, updated)
      {:reply, updated, new}
    else
      {:reply, member, state}
    end
  end

  def handle_call({:target, message}, _from, state) do
    if Local.is_local?(message.target) do
      {:reply, :__SERVER__, state}
    else
      distanced = Enum.map(state, fn {_k, v} -> Key.distance(message.target, v.key) end)
    
      min = Enum.min(distanced)
      member = Enum.find(state, fn x -> min == Key.distance(message.target, x) end)
      {:reply, member, state}
    end
  end

  def handle_call(:export, _from, state) do
    active = Enum.filter(state, fn {_k, v} ->
      v.key != nil
    end)
    exportable = Enum.map(active, fn {k, v} ->
      member = Member.export(k)
      {v.key, %{
	  ip: member.ip,
	  port: member.port,
	  public: member.public,
       }}
    end)
    transformed = Enum.into(exportable, %{})
    {:reply, transformed, state}
  end

  def handle_info({:DOWN, ref, _, _, _}, state) do
    item = get_key(state, ref)
    new = Map.pop(state, item.id, state) |> elem(1)
    {:noreply, new}
  end

  def get_key(state, ref) do
    Enum.find(state, fn {_k, v} -> v.ref == ref end) |> elem(1)
  end
end
