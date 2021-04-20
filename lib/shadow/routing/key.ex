defmodule Shadow.Routing.Key do

  use Bitwise
  
  def new do
    Stream.repeatedly(fn -> :rand.uniform 255 end) |> Enum.take(20) |> :binary.list_to_bin() |> :binary.decode_unsigned()
  end

  def distance(source, target) do
    source ^^^ target
  end
end
