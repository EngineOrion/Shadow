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
    updated = Map.merge(message, %{history: []})
    target = Routing.target(updated)
    Routing.send(target, updated)
  end

  def test_send(target, body) do
    msg = %{type: 0, source: 1000, target: target, timestamp: 0, history: [], body: body}
    encoded = Jason.encode!(msg) <> "\n"
    targetMember = Routing.target(msg)
    Routing.send(targetMember, encoded)
  end
end
