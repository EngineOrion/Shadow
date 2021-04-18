defmodule Shadow.DynamicHandler do
  use DynamicSupervisor

  def start_link(_) do
    # Register globally (chane for registry or multiple supervisors)
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(socket) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Shadow.Listener.Handler, socket}
    )
  end

  def count do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
