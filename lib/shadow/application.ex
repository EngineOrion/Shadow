defmodule Shadow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Shadow.Worker.start_link(arg)
      # {Shadow.Worker, arg}
      {Shadow.Intern.Supervisor, []},
      listener(),
      {Shadow.Routing, []},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shadow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Listener process
  defp listener() do
    %{
        id: Shadow.Listener,
        start: {Shadow.Listener, :start_link, [port()]},
        type: :worker,
        restart: :permanent,
      }
  end

  # Can fail if config error!
  defp port() do
    Application.fetch_env!(:shadow, :port)
  end
end
