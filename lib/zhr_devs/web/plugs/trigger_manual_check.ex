defmodule ZhrDevs.Web.Plugs.TriggerManualCheck do
  @moduledoc """
  This plug is responsible for triggering the manual check for the task.
  """

  @behaviour Plug

  import Plug.Conn

  import ZhrDevs.Web.Shared, only: [send_json: 3]

  import ZhrDevs.Web.Presentation.Helper

  alias ZhrDevs.Submissions.Commands

  def init([]), do: []

  def call(
        %{body_params: %{"taskUUID" => task_uuid}} = conn,
        _opts
      ) do
    triggered_by = get_session(conn, :hashed_identity)

    case Commands.TriggerManualCheck.dispatch(
           triggered_by: triggered_by,
           submissions: [],
           task_uuid: task_uuid
         ) do
      :ok ->
        send_json(conn, 200, %{status: "ok"})

      {:error, reason} when is_binary(reason) ->
        send_json(conn, 422, %{error: reason})

      {:error, error} ->
        send_json(conn, 422, %{error: error |> extract_error() |> inspect()})
    end
  end
end
