defmodule MinidoteSetAWOPTest do
  use ExUnit.Case

  @moduledoc """
  Integration test for Set_AW_OP using Minidote API.
  """

  setup_all do
  case Minidote.Server.start_link([]) do
    {:ok, _} -> :ok
    {:error, {:already_started, _}} -> :ok
  end
end


  test "add and remove elements in an Add-Wins Set" do
    key = {"my_set", Set_AW_OP, "test_bucket"}

    # Add "x" and "y"
    {:ok, clock1} =
      Minidote.update_objects([
        {key, :add, "x"},
        {key, :add, "y"}
      ], :ignore)

    # Remove "x"
    {:ok, clock2} =
      Minidote.update_objects([{key, :remove, "x"}], clock1)

    # Final read: should return only "y"
    {:ok, [{^key, value}], _} =
      Minidote.read_objects([key], clock2)

    assert value == MapSet.new(["y"])
  end
end
