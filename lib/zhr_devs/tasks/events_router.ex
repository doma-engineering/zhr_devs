defmodule ZhrDevs.Tasks.EventsRouter do
  @moduledoc """
  The events router allows you to dispatch commands to other aggregates in response to domain events.

  This particular router is used to dispatch the commands in the Submissions domain.
  It will use the :submission_identity field of the Commands.SubmitSolution struct which is a composite identifier (see ZhrDevs.Submissions.SubmissionIdentity).

  There are two ways to specify the `identity` to dispatch correct events to:
  1. Use the `identify` macro:
    identify Aggregates.Submission, by: :hashed_identity
  2. specify the :identity directly in the dispatch macro:
    dispatch(Commands.SubmitSolution, to: Aggregates.Submission, identity: :hashed_identity)


  Read more about distpatching commands: https://github.com/commanded/commanded/blob/master/guides/Commands.md#command-dispatch-and-routing
  """

  use Commanded.Commands.Router

  alias ZhrDevs.Tasks.{Aggregates, Commands}

  identify(Aggregates.Task, by: :task_identity)

  dispatch(Commands.SupportTask, to: Aggregates.Task)
  dispatch(Commands.ChangeTaskMode, to: Aggregates.Task)
end
