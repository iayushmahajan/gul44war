defmodule MinidoteTest do
  use ExUnit.Case

  @moduledoc """
  Integration test for Minidote using the Counter_PN_OB CRDT.
  Ensures API works and clock propagation is correct.
  """

  setup_all do
  case Minidote.Server.start_link([]) do
    {:ok, _} -> :ok
    {:error, {:already_started, _}} -> :ok
  end
end


  test "increments and reads counter using Minidote API" do
    key = {"my_counter", Counter_PN_OB, "test_bucket"}

    # Step 1: Increment by 5
    {:ok, clock1} =
      Minidote.update_objects([{key, :increment, 5}], :ignore)

    # Step 2: Check that counter is now 5
    {:ok, [{^key, 5}], clock2} =
      Minidote.read_objects([key], clock1)

    # Step 3: Decrement by 2
    {:ok, clock3} =
      Minidote.update_objects([{key, :decrement, 2}], clock2)

    # Step 4: Final value should be 3
    {:ok, [{^key, 3}], _clock4} =
      Minidote.read_objects([key], clock3)
  end
end
