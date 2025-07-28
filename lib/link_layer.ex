defmodule LinkLayer do
  # API
  def start_link(group_name) do GenServer.start_link(LinkLayerDistr, group_name) end
  def send(ll, data, node) do GenServer.call(ll, {:send, data, node}) end
  def register(ll, receiver) do GenServer.call(ll, {:register, receiver}) end
  def all_nodes(ll) do GenServer.call(ll, :all_nodes) end
  @spec other_nodes(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: any()
  def other_nodes(ll) do GenServer.call(ll, :other_nodes) end
  def this_node(ll) do GenServer.call(ll, :this_node) end

  def broadcast(msg) do
  {:ok, members} = all_nodes(__MODULE__)
  Enum.each(members, fn pid ->
    if pid != self(), do: GenServer.cast(pid, {:remote, msg})
  end)
end


end
