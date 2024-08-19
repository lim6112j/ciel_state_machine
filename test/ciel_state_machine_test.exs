defmodule CielStateMachineTest do
  use ExUnit.Case
  doctest CielStateMachine

  test "greets the world" do
    assert CielStateMachine.hello() == :world
  end
end
