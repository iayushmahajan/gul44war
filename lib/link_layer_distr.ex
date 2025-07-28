defmodule LinkLayerDistr do
  use GenServer
  require Logger
  # Callbacks

  def child_spec(arg) do
  %{
    id: __MODULE__,
    start: {__MODULE__, :start_link, [arg]},
    type: :worker,
    restart: :permanent,
    shutdown: 500
  }
  end

  @impl true
  def init({group_name, respond_to}) do
  spawn_link(&find_other_nodes/0)
  :pg.start_link()
  :pg.join(group_name, self())
  {:ok, %{group_name: group_name, respond_to: respond_to}}
  end


  @impl true
  def handle_call({:send, data, node}, _from, state) do
    GenServer.cast(node, {:remote, data})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:register, r}, _from, state) do
    {:reply, :ok, %{state | :respond_to => r}}
  end

  @impl true
  def handle_call(:all_nodes, _from, state) do
    members = :pg.get_members(state[:group_name])
    {:reply, {:ok, members}, state}
  end

  @impl true
  def handle_call(:other_nodes, _from, state) do
    members = :pg.get_members(state[:group_name])
    other_members = for n <- members, n !== self(), do: n
    {:reply, {:ok, other_members}, state}
  end

  @impl true
  def handle_call(:this_node, _from, state) do
    {:reply, {:ok, self()}, state}
  end

  @impl true
  def handle_cast({:remote, {:crdt_update, sender, key, op, crdt_state}}, state) do
  send(state.respond_to, {:crdt_update, sender, key, op, crdt_state})
  {:noreply, state}
  end



  def find_other_nodes() do
    nodes = os_or_app_env()
    Logger.notice("Connecting #{node()} to other nodes: #{inspect nodes}")
    try_connect(nodes, 500)
  end

  defp try_connect(nodes, t) do
    {ping, pong} = :lists.partition(fn(n) -> :pong == :net_adm.ping(n) end, nodes)
    for n <- ping do Logger.notice("Connected to node #{n}") end
    case t > 1000 do
      true ->
          for n <- pong do Logger.notice("Failed to connect #{node()} to node #{n}") end
      _ ->
          :ok
    end
    case pong do
      [] ->
          Logger.notice("Connected to all nodes")
      _ ->
          :timer.sleep(t)
          try_connect(pong, min(2 * t, 60000))
    end
  end

  def os_or_app_env() do
    nodes = :string.tokens(:os.getenv(~c"MINIDOTE_NODES", ~c""), ~c",")
    case nodes do
      ~c"" ->
          :application.get_env(:microdote, :microdote_nodes, [])
      _ ->
          for n <- nodes do :erlang.list_to_atom(n) end
    end
  end

  def start_link(group_name) do
  GenServer.start_link(__MODULE__, group_name, name: LinkLayer)
end



end
