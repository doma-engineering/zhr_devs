defmodule ZhrDevs.Submissions.ReadModels.TournamentRuns do
  @moduledoc """
  Keeps track of the multiplayer runs for the particular task
  """

  alias Uptight.Text, as: T

  use GenServer

  def start_link(opts \\ []) do
    %T{} = task_uuid = Keyword.fetch!(opts, :task_uuid)

    GenServer.start_link(__MODULE__, [], name: via_tuple(task_uuid))
  end

  def get_tournament_results(%T{} = task_uuid, hashed_identity) do
    GenServer.call(via_tuple(task_uuid), {:get_tournament_results, hashed_identity})
  end

  def add_tournament_result(%T{} = task_uuid, result) do
    GenServer.cast(via_tuple(task_uuid), {:add_tournament_result, result})
  end

  def stop(%T{} = task_uuid) do
    GenServer.stop(via_tuple(task_uuid))
  end

  # Server

  def init([]) do
    {:ok, []}
  end

  def handle_cast({:add_tournament_result, result}, state) do
    sorted_result = Enum.sort_by(result, & &1["score"])

    {:noreply, [sorted_result | state]}
  end

  def handle_call({:get_tournament_results, hashed_identity}, _from, state) do
    {:reply, do_get_tournament_results(hashed_identity, state), state}
  end

  defp do_get_tournament_results(_hashed_id, []), do: []

  defp do_get_tournament_results(hashed_id, [latest_results | _] = state) do
    Enum.map(latest_results, fn
      %{hashed_id: ^hashed_id} = entry ->
        Map.put(entry, :me, true)

      entry ->
        Map.put(entry, :me, false)
    end)
  end

  defp via_tuple(%T{} = task_uuid) do
    {:via, Registry, {ZhrDevs.Registry, {:tournament_runs, task_uuid}}}
  end
end
