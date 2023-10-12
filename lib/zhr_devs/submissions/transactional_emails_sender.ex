defmodule ZhrDevs.Submissions.TransactionalEmailsSender do
  @moduledoc """
  This is the special event-handler, that we will use to send transactional emails.

  The idea is to not rebuild the state for this event handler every time we start the application,
  but rather rely on event store to store the last sent event.
  """

  require Logger

  use Commanded.Event.Handler,
    application: ZhrDevs.App,
    name: __MODULE__,
    start_from: :current

  alias ZhrDevs.{Email, Mailer}

  alias ZhrDevs.Submissions.Events.SolutionSubmitted

  @retry_delay_milliseconds 10_000

  def handle(%SolutionSubmitted{} = solution_submitted, _meta) do
    %ZhrDevs.Task{} =
      task =
      ZhrDevs.Tasks.ReadModels.AvailableTasks.get_task_by_uuid(solution_submitted.task_uuid)

    maybe_notify_operator(solution_submitted, task)
  end

  def error(_, event, %{context: %{failures: 3}}) do
    Logger.error(
      "[#{__MODULE__}] Failed to handle an event: #{inspect(event)} 3 times in a row, giving up."
    )

    {:stop, :max_retries_reached}
  end

  def error({:error, _} = error, event, %{context: context}) do
    Logger.error(
      "[#{__MODULE__}] Failed to handle an event: #{inspect(event)}, error: #{inspect(error)} retrying in #{@retry_delay_milliseconds} ms."
    )

    context = Map.update(context, :failures, 1, fn failures -> failures + 1 end)

    {:retry, @retry_delay_milliseconds, context}
  end

  defp maybe_notify_operator(%SolutionSubmitted{trigger_automatic_check: false} = event, task) do
    opts = [
      task_name: task.name,
      technology: task.technology,
      submission_url: submission_url(event.uuid),
      hashed_identity: event.hashed_identity
    ]

    opts
    |> Email.solution_submitted()
    |> Mailer.deliver_now()
    |> case do
      {:ok, _email} ->
        :ok

      error ->
        error
    end
  end

  defp maybe_notify_operator(_solution_submitted, _task) do
    # Skip notifying operator if automatic check is enabled

    :ok
  end

  defp submission_url(uuid) do
    %URI{
      scheme: System.get_env("PUBLIC_SCHEME", "http"),
      host: System.get_env("PUBLIC_HOST", "localhost"),
      path: "/my/submission/#{uuid}/download"
    }
    |> URI.to_string()
  end
end
