defmodule Shadow do
  @moduledoc """
  Documentation for `Shadow`.

  Entry point & (admin) interface for the node.
  """

  alias Shadow.Routing

  @doc """
  Send / process any message. 
  message must be of type Shadow.Routing.Message
  """
  def send(message) do
    target = Routing.target(message)
    Routing.send(target, message)
  end
  
end
