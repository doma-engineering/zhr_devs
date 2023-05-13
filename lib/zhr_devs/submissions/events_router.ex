defmodule ZhrDevs.Submissions.EventsRouter do
  @moduledoc """
  The events router allows you to dispatch commands to other aggregates in response to domain events.

  This particular router is used to dispatch the commands in the Submissions domain.
  """

  use Commanded.Commands.Router

  alias ZhrDevs.Submissions.{Aggregates, Commands}

  dispatch(Commands.SubmitSolution, to: Aggregates.Submission, identity: :submission_identity)
end
