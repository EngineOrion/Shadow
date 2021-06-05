defmodule Shadow do
  @moduledoc """
  Entry point & interface for the node.
  """

  alias Shadow.Routing

  @doc """
  Send / process any message.
  message must be of type Shadow.Routing.Message
  """
  def send(message) do
    updated = Map.merge(message, %{history: []})
    target = Routing.target(updated)
    Routing.send(target, updated)
  end

  @doc """
  Simple function to send a fully configured message through the system.
  """
  def test_send(target, body) do
    msg = %{type: 0, source: 1000, target: target, timestamp: 0, body: body}
    encoded = Jason.encode!(msg) <> "\n"
    targetMember = Routing.target(msg)
    Routing.send(targetMember, encoded)
  end
end
