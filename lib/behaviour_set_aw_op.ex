defmodule Set_AW_OP do
  @behaviour CRDT

  @moduledoc """
  Documentation for `Set_AW_OP`.

  An operation-based Observed-Remove Set CRDT.

  Reference papers:
  Marc Shapiro, Nuno Preguiça, Carlos Baquero, Marek Zawirski (2011)
  A comprehensive study of Convergent and Commutative Replicated Data Types
  """

  # ToDo: Add type spec
  @type t :: :set_aw_op

  def new() do
    %{
      adds: %{},
      removes: MapSet.new()
    }
  end


  def value(%{adds: adds, removes: removes}) do
  adds
  |> Enum.filter(fn {element, tag_set} ->
    Enum.any?(tag_set, fn tag -> not MapSet.member?(removes, {element, tag}) end)
  end)
  |> Enum.map(fn {element, _tags} -> element end)
  |> MapSet.new()
end


  def downstream({:add, element}, %{adds: adds}) do
    tag = {node(), System.unique_integer([:monotonic, :positive])}

    {:ok, {:add, element, tag}}
  end

  def downstream({:remove, element}, %{adds: adds}) do
    case Map.get(adds, element) do
      nil -> {:ok, []}
      tag_set ->
        effects = Enum.map(tag_set, fn tag -> {:remove, element, tag} end)
        {:ok, effects}
    end
  end


  def update({:add, element, tag}, %{adds: adds, removes: removes} = state) do
    new_tags = Map.update(adds, element, MapSet.new([tag]), fn set ->
      MapSet.put(set, tag)
    end)

    {:ok, %{state | adds: new_tags}}
  end

  def update({:remove, element, tag}, %{adds: adds, removes: removes} = state) do
    new_removes = MapSet.put(removes, {element, tag})
    {:ok, %{state | removes: new_removes}}
  end


  def equal(state1, state2) do
    state1.adds == state2.adds and state1.removes == state2.removes
  end


  # all operations require state downstream
  def require_state_downstream({add, _}) do true end
  def require_state_downstream({add_all, _}) do true end
  def require_state_downstream({remove, _}) do true end
  def require_state_downstream({remove_all, _}) do true end
  def require_state_downstream({reset, {}}) do true end

end
