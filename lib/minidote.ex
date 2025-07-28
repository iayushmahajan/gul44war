defmodule Minidote do
  require Logger

  @moduledoc """
  Documentation for `Minidote`.
  This is the API file for your Minidote
  Feel free to modify this and all other files of the template to your hearts content.
  """

  # ToDo: Improve type spec

  @type key :: {binary(), CRDT.t(), binary()}
  @type clock :: any() # your clock type here


  def start_link(server_name) do
    # if you need arguments for initialization, change here
    GenServer.start_link(Minidote.Server, [], name: server_name)
  end

  @spec read_objects([key()], clock() | :ignore) ::
    {:ok, [any()], clock()} | {:error, any()}
  def read_objects(objects, clock) do
    GenServer.call(Minidote.Server, {:read_objects, objects, clock})
  end

  @spec update_objects([{key(), atom(), any()}], clock()) ::
    {:ok, clock()} | {:error, any()}
  def update_objects(updates, clock) do
    GenServer.call(Minidote.Server, {:update_objects, updates, clock})
  end

end
