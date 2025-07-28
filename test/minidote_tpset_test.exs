defmodule MinidoteTPSetTest do
  use ExUnit.Case

  @moduledoc """
  Integration test for Behaviour_TPSet using Minidote API.
  """

  setup_all do
    case Minidote.Server.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  test "TPSet prevents re-adding removed elements" do
    key = {"my_tpset", Behaviour_TPSet, "bucket"}

    # Step 1: Add "a" and "b"
    {:ok, clock1} =
      Minidote.update_objects([
        {key, :add, "a"},
        {key, :add, "b"}
      ], :ignore)

    # Step 2: Remove "a"
    {:ok, clock2} =
      Minidote.update_objects([{key, :remove, "a"}], clock1)

    # Step 3: Try to re-add "a" (should be ignored)
    {:ok, clock3} =
      Minidote.update_objects([{key, :add, "a"}], clock2)

    # Step 4: Read final value
    {:ok, [{^key, value}], _} =
      Minidote.read_objects([key], clock3)

    assert value == MapSet.new(["b"])
  end
end
