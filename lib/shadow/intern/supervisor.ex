defmodule Shadow.Intern.Supervisor do
  @moduledoc """
  Dynamic supervisor for managing Member connections.
  """

  use DynamicSupervisor
  
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, restart: :temporary, max_restarts: 0)
  end

  def start_in(opts) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Shadow.Routing.Member, {:in, opts}}
    )
  end

  def start_out(opts) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Shadow.Routing.Member, {:out, opts}}
    )
  end
end
