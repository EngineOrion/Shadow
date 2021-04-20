defmodule Shadow.Routing.Message do

  def process(data) do
    with {:ok, message} <- Jason.decode(data) do
      process(Map.fetch!(message, "type"), Map.fetch!(message, "body"))
    else
      _ -> {:error, "Messaging Error!"}
    end
  end

  def process(2, body) do
    %{
      type: 2,
      ip: Map.fetch!(body, "ip"),
      port: Map.fetch!(body, "port"),
      public: Map.fetch!(body, "public"),
      key: Map.fetch!(body, "key"),
    }
  end
end
