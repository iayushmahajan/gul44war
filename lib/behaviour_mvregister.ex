defmodule Behaviour_MVRegister do
  @behaviour CRDT

  @moduledoc """
  Multi-Value Register (MVRegister) CRDT.
  Keeps a set of concurrently written values, resolved via vector clocks.
  """

  @type clock :: %{node() => non_neg_integer()}
  @type value :: any()
  @type t :: [{clock(), value()}]

  @impl true
  def new, do: []

  @impl true
  def value(state) do
    Enum.map(state, fn {_clock, v} -> v end)
    |> MapSet.new()
  end

  @impl true
  def downstream({:set, value}, state) do
    clock = increment_clock(current_clock(state), node())
    {:ok, {:set, {clock, value}}}
  end

  @impl true
  def update({:set, {incoming_clock, value}}, state) do
    # Remove entries that are dominated by the new clock
    kept =
      Enum.reject(state, fn {clock, _} ->
        dominates?(incoming_clock, clock)
      end)

    # Only add if it's not already included
    already_present =
      Enum.any?(kept, fn {clock, val} -> clock == incoming_clock and val == value end)

    new_state = if already_present, do: kept, else: [{incoming_clock, value} | kept]
    {:ok, new_state}
  end

  @impl true
  def equal(state1, state2) do
    MapSet.new(state1) == MapSet.new(state2)
  end

  @impl true
  def require_state_downstream(_op), do: false

  # Utility: get current merged clock
  defp current_clock(state) do
    Enum.reduce(state, %{}, fn {clock, _}, acc -> merge_clocks(acc, clock) end)
  end

  # Utility: increment local clock
  defp increment_clock(clock, node) do
    Map.update(clock, node, 1, &(&1 + 1))
  end

  # Clock merge
  defp merge_clocks(clock1, clock2) do
    Map.merge(clock1, clock2, fn _k, v1, v2 -> max(v1, v2) end)
  end

  # Clock comparison (dominates = ≥ for all keys, and > for some)
  defp dominates?(c1, c2) do
    keys = Map.keys(c1) ++ Map.keys(c2) |> Enum.uniq()
    all_ge = Enum.all?(keys, fn k -> Map.get(c1, k, 0) >= Map.get(c2, k, 0) end)
    any_gt = Enum.any?(keys, fn k -> Map.get(c1, k, 0) > Map.get(c2, k, 0) end)
    all_ge and any_gt
  end
end
