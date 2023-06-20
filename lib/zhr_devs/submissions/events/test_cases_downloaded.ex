defmodule ZhrDevs.Submissions.Events.TestCasesDownloaded do
  @moduledoc """
  Represents an event that is emitted when user is allowed to download a task after the first submission.

  We will send an extended version of task adding the test cases to it.
  """
  alias Uptight.Base.Urlsafe
  alias Uptight.Text, as: T

  alias ZhrDevs.Submissions.Events.TaskDownloaded

  @derive Jason.Encoder
  defstruct TaskDownloaded.fields()

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_id) => T.t(),
          required(:technology) => atom()
        }
end
