defmodule Shadow.Routing do
  @moduledoc """

  Core decision unit of the Shadow-System. The routing system is
  responsible for determining where packets should be sent, as well as
  supervising the possible targets.

  """

  use GenServer

  alias Shadow.Intern.Supervisor
  alias Shadow.Routing.Member
  alias Shadow.Routing.Key
  alias Shadow.Intern.Helpers

  defstruct [:key, :active, :ref, :timestamp]

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :routing)
  end

  def init(_) do
    {:ok, %{}}
  end

  @doc """
  Creates a non active process, with state for both the new process state & updated routing table.
  
  Temporary Key: Passed to the Member Process until it is active.

  """
  def new(socket) do
    GenServer.call(:routing, {:new, socket})
  end

  def activate(key, message) do
    GenServer.call(:routing, {:activate, key, message})
  end

  def handle_call({:new, socket}, _from, state) do
    temporary = Key.new()
    member = %Member{key: temporary, socket: socket}
    routing = %__MODULE__{key: temporary, active: false, timestamp: Helpers.unix_now()}
    with {:ok, pid} <- Supervisor.start_child(member) do
      ref = Process.monitor(pid)
      full = Map.put(routing, :ref, ref)
      new = Map.put(state, temporary, full)
      {:reply, pid, new}
    else
      _ -> {:error, "Supervisor failed."}
    end
  end

  def handle_call({:activate, key, message}, _from, state) do
    member = Map.get(state, key)
    updated = %__MODULE__{
      key: message.key,
      ref: member.ref,
      timestamp: member.timestamp,
      active: true
    }
    # Remove old (temp) key
    cleared = Map.pop(state, key)
    new = Map.put(cleared, message.key, updated)
    {:reply, updated, new}
  end

  def handle_info({:DOWN, ref, _, _, _}, state) do
    item = get_key(state, ref)
    new = Map.pop(state, item.key, state) |> elem(1)
    {:noreply, new}
  end

  def get_key(state, ref) do
    Enum.find(state, fn {_k, v} -> v.ref == ref end) |> elem(1)
  end
  
end
