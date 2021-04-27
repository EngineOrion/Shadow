defmodule Shadow.Intern.Supervisor do
  @moduledoc """
  Dynamic supervisor for managing Member connections.

  Restarting issue:

  In theory processes shouldn't restart if the termination reason was
  normal. But in the current implementation that isn't happening.
  Therefor currently all Members have a restart limit of 0, so they
  can't be restarted.
  """

  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, restart: :temporary, max_restarts: 0)
  end

  @doc """
  Start a new member for incoming connections.
  """
  def start_in(opts) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Shadow.Routing.Member, {:in, opts}}
    )
  end

  @doc """
  Start a new member for outgoing connections. 
  """
  def start_out(opts) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Shadow.Routing.Member, {:out, opts}}
    )
  end
end
