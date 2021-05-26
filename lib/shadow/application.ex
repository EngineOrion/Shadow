defmodule Shadow.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Shadow.Intern.Supervisor, []},
      listener(),
      {Shadow.Routing, []},
      {Shadow.Intern.Registry, []},
      {Shadow.Local.Portal, []},
    ]

    opts = [strategy: :one_for_one, name: Shadow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp listener() do
    %{
      id: Shadow.Listener,
      start: {Shadow.Listener, :start_link, [Shadow.Intern.Helpers.port()]},
      type: :worker,
      restart: :permanent
    }
  end
end
