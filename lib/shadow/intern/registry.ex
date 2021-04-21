defmodule Shadow.Intern.Registry do
  use GenServer

  def start_link(_state) do
    GenServer.start_link(__MODULE__, nil, name: name())
  end

  def whereis_name(name) do
    GenServer.call(name(), {:whereis_name, name})
  end

  def register_name(name, pid) do
    GenServer.call(name(), {:register_name, name, pid})
  end

  def get_all() do
    GenServer.call(name(), {:get_all})
  end

  def unregister_name(name) do
    GenServer.cast(name(), {:unregister_name, name})
  end

  def send(name, message) do
    case whereis_name(name) do
      :undefined ->
        {:badarg, {name, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  # SERVER

  def init(_) do
    {:ok, Map.new()}
  end

  def handle_call({:whereis_name, name}, _from, state) do
    {:reply, Map.get(state, name, :undefined), state}
  end

  def handle_call({:get_all}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:register_name, name, pid}, _from, state) do
    case Map.get(state, name) do
      nil ->
        {:reply, :yes, Map.put(state, name, pid)}

      _ ->
        {:reply, :no, state}
    end
  end

  def handle_cast({:unregister_name, name}, state) do
    {:noreply, Map.delete(state, name)}
  end

  def name() do
    :registry
  end
end
