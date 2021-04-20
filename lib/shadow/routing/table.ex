defmodule Shadow.Routing.Table do
  @moduledoc """
  Struct & helper functions for the kademlia routing table.
  """

  @derive Jason.Encoder
  defstruct members: %{} 

  def save(table) do
    Jason.encode(table)
  end
end
