defmodule Shadow.Routing.Table do
  @moduledoc """
  Datastructure and related functions for routing informations.
  """

  alias Shadow.Routing.Self
  alias Shadow.Routing.Remote

  use GenServer

  defstruct self: %Self{},
            remotes: %Remote{}

  def start_link(_state) do
    GenServer.start_link(__MODULE__, [], name: name())
  end

  def getTable() do
    GenServer.call(name(), :get)
  end

  # - - - - - - - - - - - - - - - - - - -

  def init(_state) do
    initial = %__MODULE__{
      self: Shadow.Routing.Self.get(),
      remotes: [%Shadow.Routing.Remote{}]
    }

    {:ok, initial}
  end

  def handle_call(:get, _from, table) do
    {:reply, table, table}
  end

  defp name() do
    :routing
  end
end
