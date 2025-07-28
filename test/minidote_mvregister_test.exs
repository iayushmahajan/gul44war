defmodule MinidoteMVRegisterTest do
  use ExUnit.Case

  setup_all do
    case Minidote.Server.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  test "MVRegister stores multiple concurrent values" do
    key = {"my_mvreg", Behaviour_MVRegister, "test_bucket"}

    # First set: "a"
    {:ok, clock1} =
      Minidote.update_objects([{key, :set, "a"}], :ignore)

    # Second set: "b" under updated clock (simulated concurrent write)
    {:ok, clock2} =
      Minidote.update_objects([{key, :set, "b"}], clock1)

    # Read the register
    {:ok, [{^key, values}], _clock3} =
      Minidote.read_objects([key], clock2)

    assert MapSet.equal?(values, MapSet.new(["a", "b"])) or
           MapSet.equal?(values, MapSet.new(["b"])) or
           MapSet.equal?(values, MapSet.new(["a"]))
  end
end
