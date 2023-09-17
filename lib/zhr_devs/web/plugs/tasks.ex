defmodule ZhrDevs.Web.Plugs.Tasks do
  @moduledoc """
  This plug is responsible for returning of a submissions,
  which will be using to display the breakdown of how many attempts each 'task' user takes
  """

  @behaviour Plug

  import Plug.Conn

  import ZhrDevs.Web.Shared, only: [send_json: 3]

  def init([]), do: []

  def call(conn, _opts) do
    send_json(conn, 200, %{tasks: get_submissions(conn)})
  end

  defp get_submissions(conn) do
    conn
    |> get_session(:hashed_identity)
    |> ZhrDevs.Submissions.attempts()
  end
end
