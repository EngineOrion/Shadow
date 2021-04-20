defmodule Shadow.Routing do
  @moduledoc """

  Core decision unit of the Shadow-System. The routing system is
  responsible for determining where packets should be sent, as well as
  supervising the possible targets.

  """

  use GenServer

  alias Shadow.Routing.Table
  alias Shadow.Intern.Supervisor
  alias Shadow.Routing.Member
  alias Shadow.Routing.Key
  alias Shadow.Intern.Helpers

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

  def get() do
    GenServer.whereis(:routing)
  end

  def handle_call({:new, socket}, _from, state) do
    temporary = Key.new()
    member = %Member{key: temporary, timestamp: Helpers.unix_now(), active: false}
    with {:ok, pid} <- Supervisor.start_child(Map.put(member, :socket, socket)) do
      ref = Process.monitor(pid)
      full = Map.put(member, :ref, ref)
      new = Map.put(state, temporary, full)
      {:reply, pid, new}
    else
      _ -> {:error, "Supervisor failed."}
    end
  end

  def handle_info({:DOWN, ref, _, _, _}, state) do
    Enum.each(state, fn {k, v} ->
      if v.ref == ref do
	new = Map.pop(state, k) |> elem(1)
	{:noreply, new}
      end
    end)
  end
end
