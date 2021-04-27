defmodule Shadow.Routing.Message do
  @moduledoc """
  
  Central processing point for incoming & outgoing messages.

  The process/1 function will decode the incoming message and then
  call itself with the type using overloading. 
  
  All process/2 functions should return {:ok, %__MODULE__{}}.
  
  Warning: This module currently is only responsible for incoming
  messages, generated messages will get encoded directly.
  TODO: Add encode functions & process all messages through that.
  
  It is possible to pattern match on values inside structs. It would
  be easier to directly match on the type there, instead of the
  dedicated value. 
  TODO: Pattern match on type inside struct.
  """
  
  @typedoc """
  Structure for all messages in the system. Most messages follow the
  normal source -> target structure, with more data in the body. In
  addition "type" is used for special messages that are usually part
  of the mechanism.
  
  Timestamp: Currently unused, will later determine whether a message
  is worth forwarding or has been in the system for to long. (age >
  threshold -> disregard)
  """
  defstruct [:type, :source, :target, :timestamp, :body]

  alias Shadow.Intern.Helpers

  @doc """
  Entry point for the processing system. It will decode each incoming
  (binray) message into a map and extract the type. From there the
  different process/2 functions are called.
  """
  def process(data) do
    with {:ok, message} <- Jason.decode(data),
      {:ok, type} <- Map.fetch(message, "type") do
      process(type, message)
    else
      _ -> {:error, "Message not valid!"}
    end
  end

  @doc """
  Type 0: Direct message.
  
  This message type should be regarded as a simple direct message,
  comparable to HTTP Post, except there is currently no kind of
  response (planned for v1).
  """
  def process(0, message) do
    %__MODULE__{
      type: 0,
      source: Map.fetch!(message, "source"),
      target: Map.fetch!(message, "target"),
      timestamp: Map.fetch!(message, "timestamp"),
      body: Map.fetch!(message, "body")
    }
  end

  @doc """
  Type 2: Activation
  
  Message from one node to another for activation purposes. Its body
  contains the key, ip, port, public of the connected member node. 
  
  Should any field not be valid an error will be returned.
  """
  def process(2, message) do
    with {:ok, body} <- Map.fetch(message, "body"),
	 {:ok, ip} <- Map.fetch(body, "ip"),
	 {:ok, port} <- Map.fetch(body, "port"),
	 {:ok, public} <- Map.fetch(body, "public"),
	 {:ok, key} <- Map.fetch(body, "key")
      do
      %__MODULE__{
	type: 2,
	body: %{
	  key: key,
	  ip: ip,
	  port: port,
	  public: public
	},
	timestamp: Helpers.unix_now()
      }
    else
      _ -> {:error, "Message not valid!"}
    end
  end

  @doc """
  Type 3: Activation Confirmation
  
  Since the actual body is irrelevant for an activation confirmation
  :ok is returned instead.
  """
  def process(3, _message) do
    :ok
  end
end
