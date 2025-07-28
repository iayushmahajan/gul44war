defmodule Behaviour_TPSetExpanded do
  @behaviour CRDT

  @moduledoc """
  A two-phase set where each element is uniquely tagged with an ID.
  Once an element is removed, it cannot be re-added (like regular TPSet), but allows duplicate values.
  """

  @type element :: any()
  @type id :: non_neg_integer()
  @type tagged_element :: {id(), element()}
  @type t :: {MapSet.t(tagged_element()), MapSet.t(tagged_element())}

  @impl true
  def new do
    {MapSet.new(), MapSet.new()}
  end

  @impl true
  def value({adds, removes}) do
    MapSet.difference(adds, removes)
    |> Enum.map(fn {_id, val} -> val end)
    |> MapSet.new()
  end

  @impl true
  def downstream({:add, element}, {adds, removes}) do
  already_removed? =
    Enum.any?(removes, fn {_id, val} -> val == element end)

  if already_removed? do
    {:ok, []}  # or {:error, :already_removed}
  else
    id = System.unique_integer([:positive])
    {:ok, {:add, {id, element}}}
  end
end


  def downstream({:remove, element}, {adds, _removes}) do
    matching = MapSet.filter(adds, fn {_id, val} -> val == element end)
    {:ok, {:remove, matching}}
  end

  @impl true
  def update({:add, {id, element}}, {adds, removes}) do
    new_adds = MapSet.put(adds, {id, element})
    {:ok, {new_adds, removes}}
  end

  def update({:remove, to_remove}, {adds, removes}) do
    new_removes = MapSet.union(removes, to_remove)
    {:ok, {adds, new_removes}}
  end

  @impl true
  def equal({adds1, rem1}, {adds2, rem2}) do
    MapSet.equal?(adds1, adds2) and MapSet.equal?(rem1, rem2)
  end

  @impl true
  def require_state_downstream({op, _arg}) when op == :add, do: false
  def require_state_downstream({:remove, _}), do: true
end
