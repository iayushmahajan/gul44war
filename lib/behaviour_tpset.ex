defmodule Behaviour_TPSet do
  @behaviour CRDT

  @moduledoc """
  A state-based Two-Phase Set (2P-Set) CRDT implementation.

  This CRDT only allows elements to be added and then removed — once removed, they cannot be added again.

  Internal state: a tuple `{add_set, remove_set}` where both are `MapSet`s.
  """

  @type t :: {MapSet.t(), MapSet.t()}

  @impl true
  def new do
    {MapSet.new(), MapSet.new()}
  end

  @impl true
  def value({add_set, remove_set}) do
    MapSet.difference(add_set, remove_set)
  end

  @impl true
  def downstream({:add, element}, _state) do
    {:ok, {:add, element}}
  end

  def downstream({:remove, element}, _state) do
    {:ok, {:remove, element}}
  end

  @impl true
  def update({:add, element}, {add_set, remove_set}) do
    {:ok, {MapSet.put(add_set, element), remove_set}}
  end

  def update({:remove, element}, {add_set, remove_set}) do
    {:ok, {add_set, MapSet.put(remove_set, element)}}
  end

  @impl true
  def equal({add1, rem1}, {add2, rem2}) do
    MapSet.equal?(add1, add2) and MapSet.equal?(rem1, rem2)
  end

  @impl true
  def require_state_downstream(_op), do: false
end
