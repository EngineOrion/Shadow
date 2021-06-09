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
    target = Routing.target(message)
    Routing.send(target, message)
  end

  @doc """
  Simple function to send a fully configured message through the system.
  """
  def test_send(target, body) do
    msg = %{type: 0, source: 0, target: target, timestamp: 0, body: body}
    encoded = Jason.encode!(msg) <> "\n"
    targetMember = Routing.target(msg)
    Routing.send(targetMember, encoded)
  end
end
