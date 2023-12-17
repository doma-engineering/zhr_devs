defmodule ZhrDevs.Web.Plugs.Submission do
  @moduledoc """
  Information regarding an individual submission page.
  """

  alias Uptight.Result

  alias ZhrDevs.Tasks.ReadModels.AvailableTasks

  alias ZhrDevs.Submissions.ReadModels.TournamentRuns

  @behaviour Plug

  import Plug.Conn

  import ZhrDevs.Web.Shared, only: [send_json: 3]

  def init([]), do: []

  def call(%{params: %{"technology" => technology, "name" => name}} = conn, _) do
    case get_details(conn, name, technology) do
      %Result.Ok{} = result ->
        send_json(conn, 200, result.ok)

      %Result.Err{} = err ->
        send_json(conn, 404, err)
    end
  end

  def call(%{params: %{"task_uuid" => _task_uuid}} = conn, _) do
    send_json(conn, 500, %{error: "Not implemented"})
  end

  def call(conn, _opts) do
    send_json(conn, 422, %{error: "Invalid parameters", status: 422})
  end

  defp get_details(conn, name, technology) do
    Result.new(fn ->
      name = String.to_existing_atom(name)
      technology = String.to_existing_atom(technology)

      me = conn |> get_session(:hashed_identity) |> Uptight.Base.mk_url!()
      %ZhrDevs.Task{} = task = AvailableTasks.get_task_by_name_technology(name, technology)
      tournament_results = TournamentRuns.get_tournament_results(task.uuid, to_string(me))

      ZhrDevs.Submissions.details(me, task, tournament_results)
    end)
  end
end
