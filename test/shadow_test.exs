defmodule ShadowTest do
  use ExUnit.Case
  doctest Shadow

  test "greets the world" do
    assert Shadow.hello() == :world
  end
end
