defmodule ZhrDevs.Web.Plugs.Submissions do
  @moduledoc """
  This plug is responsible for returning of a submissions,
  which will be using to display the breakdown of how many attempts each 'task' user takes
  """

  @behaviour Plug

  alias ZhrDevs.Tasks.ReadModels.AvailableTasks

  import Plug.Conn

  import ZhrDevs.Web.Shared, only: [send_json: 3]

  def init([]), do: []

  def call(conn, _opts) do
    send_json(conn, 200, %{tasks: get_submissions(conn)})
  end

  defp get_submissions(conn) do
    atts = conn |> get_session(:hashed_identity) |> ZhrDevs.Submissions.attempts()
    # Get all the tasks from attempts, these are keys
    att_tasks = Enum.map(atts, fn {k, _v} -> k end)
    av_tasks = AvailableTasks.get_available_tasks()
    # Tasks that aren't in submissions
    extra_tasks =
      Enum.filter(av_tasks |> IO.inspect(), fn v ->
        not Enum.member?(att_tasks, v)
      end)

    # Add extra_tasks to atts, but shape each one to be an attempt
    (Enum.map(extra_tasks, fn v ->
       {v, ZhrDevs.Submissions.ReadModels.Submission.default_counter()}
     end)
     |> ZhrDevs.Submissions.ReadModels.Submission.do_extract_attempts()) ++ atts
  end
end
