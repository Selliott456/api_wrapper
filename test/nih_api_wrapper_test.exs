defmodule NihApiWrapperTest do
  use ExUnit.Case
  doctest NihApiWrapper

  test "greets the world" do
    assert NihApiWrapper.hello() == :world
  end
end
