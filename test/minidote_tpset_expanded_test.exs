defmodule MinidoteTPSetExpandedTest do
  use ExUnit.Case

  setup_all do
    case Minidote.Server.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  test "TPSetExpanded prevents re-adding removed elements and tracks IDs" do
    key = {"my_tpsexp", Behaviour_TPSetExpanded, "test_bucket"}

    # Add "x" and "y"
    {:ok, clock1} =
      Minidote.update_objects([
        {key, :add, "x"},
        {key, :add, "y"}
      ], :ignore)

    # Remove "x"
    {:ok, clock2} =
      Minidote.update_objects([
        {key, :remove, "x"}
      ], clock1)

    # Try to re-add "x" again (should not show up)
    {:ok, clock3} =
      Minidote.update_objects([
        {key, :add, "x"}
      ], clock2)

    # Final read
    {:ok, [{^key, result}], _} =
      Minidote.read_objects([key], clock3)

    # Only "y" should remain
    assert MapSet.equal?(result, MapSet.new(["y"]))
  end
end
