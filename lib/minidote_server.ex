defmodule Minidote.Server do
  use GenServer
  require Logger

  @moduledoc """
  The API documentation for `Minidote.Server`.
  """

  @impl true
  def init(args) do
  node_name = node()
  clock = %{}

  link_pid = Process.whereis(LinkLayer)


  state = %{
    node_name: node_name,
    clock: clock,
    objects: %{},
    link: link_pid
  }

  {:ok, state}
  end


  @impl true
  def handle_call({:read_objects, keys, :ignore}, _from, state) do
    values =
      for key <- keys do
        {id, module, bucket} = key

        {module, obj_state} =
          Map.get(state.objects, key, {module, CRDT.new(module)})

        val = CRDT.value(module, obj_state)
        {key, val}
      end

    {:reply, {:ok, values, state.clock}, state}
  end

  @impl true
def handle_call({:read_objects, keys, clock}, _from, state) do
  # Wait for required clock (not implemented yet — assume local clock is always up-to-date)
  # You can later handle delayed requests here if needed.

  values =
    for key <- keys do
      {_, module, _} = key
      {module, obj_state} = Map.get(state.objects, key, {module, CRDT.new(module)})
      val = CRDT.value(module, obj_state)
      {key, val}
    end

  {:reply, {:ok, values, state.clock}, state}
end


  @impl true
def handle_call({:update_objects, updates, :ignore}, _from, state) do
  node_name = state.node_name

  {new_objects, all_messages} =
  Enum.reduce(updates, {state.objects, []}, fn {key, op, arg}, {acc, all_msgs} ->
    {id, module, bucket} = key

    {crdt_module, crdt_state} =
      case Map.get(acc, key) do
        nil -> {module, CRDT.new(module)}
        existing -> existing
      end

    {:ok, effects} = CRDT.downstream(module, {op, arg}, crdt_state)

    effects = List.wrap(effects)

    updated_state =
      Enum.reduce(effects, crdt_state, fn effect, st ->
        {:ok, st2} = CRDT.update(module, effect, st)
        st2
      end)

    updated_acc = Map.put(acc, key, {module, updated_state})

    messages =
      Enum.map(effects, fn effect ->
        {:crdt_update, node_name, key, effect, state.clock}
      end)

    {updated_acc, [messages | all_msgs]}
  end)


  flat_messages = List.flatten(all_messages)

  Enum.each(flat_messages, fn msg ->
  LinkLayer.broadcast(msg)
end)

  updated_clock = Map.update(state.clock, node_name, 1, &(&1 + 1))

  new_state = %{state | objects: new_objects, clock: updated_clock}
  {:reply, {:ok, updated_clock}, new_state}
end

@impl true
def handle_call({:update_objects, updates, clock}, _from, state) do
  node_name = state.node_name

  {new_objects, all_messages} =
    Enum.reduce(updates, {state.objects, []}, fn {key, op, arg}, {acc, all_msgs} ->
  {_, module, _} = key

  {_, crdt_state} =
    Map.get(acc, key, {module, CRDT.new(module)})

  {:ok, effects} = CRDT.downstream(module, {op, arg}, crdt_state)
  effects = List.wrap(effects)

  updated_state =
    Enum.reduce(effects, crdt_state, fn effect, st ->
      {:ok, st2} = CRDT.update(module, effect, st)
      st2
    end)

  acc = Map.put(acc, key, {module, updated_state})

  messages = Enum.map(effects, fn effect ->
    {:crdt_update, state.node_name, key, effect, state.clock}
  end)

  {acc, [messages | all_msgs]}
end)

  flat_messages = List.flatten(all_messages)
  Enum.each(flat_messages, fn msg ->
  LinkLayer.broadcast(msg)
end)


  updated_clock = Map.update(state.clock, node_name, 1, &(&1 + 1))

  new_state = %{state | objects: new_objects, clock: updated_clock}
  {:reply, {:ok, updated_clock}, new_state}
end


  @impl true
def handle_info({:crdt_update, from_node, key, effect, remote_clock}, state) do
  Logger.info("[#{node()}] Received CRDT update from #{inspect from_node}")
  {_, module, _} = key
  {crdt_module, crdt_state} =
    case Map.get(state.objects, key) do
      nil -> {module, CRDT.new(module)}
      existing -> existing
    end

  {:ok, updated_state} = CRDT.update(module, effect, crdt_state)

  updated_objects = Map.put(state.objects, key, {module, updated_state})

  # Merge vector clocks
  merged_clock = Map.merge(state.clock, remote_clock, fn _k, a, b -> max(a, b) end)

  {:noreply, %{state | objects: updated_objects, clock: merged_clock}}
end



  def start_link(args) do
  GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end


end
