defmodule ZhrDevs.Web.Plugs.Submission do
  @moduledoc """
  Information regarding an individual submission page.
  """

  alias Uptight.Result

  alias ZhrDevs.Tasks.ReadModels.AvailableTasks

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

      %ZhrDevs.Task{} = task = AvailableTasks.get_task_by_name_technology(name, technology)

      conn
      |> get_session(:hashed_identity)
      |> ZhrDevs.Submissions.details(task)
    end)
  end
end
