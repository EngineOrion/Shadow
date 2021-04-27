defmodule Shadow.Routing.Key do
  use Bitwise

  @doc """
  Generates a completly random key in the entire keyspace. This
  function will not be used beyond initial setup or resets, since
  later keys will be weightet / not random.

  Returns the new key as an integer.
  """
  def new do
    Stream.repeatedly(fn -> :rand.uniform(255) end)
    |> Enum.take(20)
    |> :binary.list_to_bin()
    |> :binary.decode_unsigned()
  end

  @doc """
  Uses bitwise logic to XOR the two keys, returning the
  "Kademlia-Distance".
  """
  def distance(source, target) do
    source ^^^ target
  end
end
