defmodule Shadow.Routing.Message do

  # Most messages will be of type 0 => normal source to target
  defstruct [:type, :source, :target, :timestamp, :body]

  # TODO: Typesafety
  def process(data) do
    with {:ok, message} <- Jason.decode(data) do
      process(Map.fetch!(message, "type"), message)
    else
      _ -> {:error, "Messaging Error!"}
    end
  end

  def process(0, message) do
    %__MODULE__{
      type: 0,
      source: Map.fetch!(message, "source"),
      target: Map.fetch!(message, "target"),
      timestamp: Map.fetch!(message, "timestamp"),
      body: Map.fetch!(message, "body"),
    }
  end

  # TODO: Migrate to struct
  def process(2, message) do
    body = Map.fetch!(message, "body")
    %{
      type: 2,
      ip: Map.fetch!(body, "ip"),
      port: Map.fetch!(body, "port"),
      public: Map.fetch!(body, "public"),
      key: Map.fetch!(body, "key"),
    }
  end
end
