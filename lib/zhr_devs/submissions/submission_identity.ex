defmodule ZhrDevs.Submissions.SubmissionIdentity do
  @moduledoc """
  This module provides a way to make the composite identifier for the Submission aggregate.

  Because our business rules require that the same person can't submit more than two solutions for the same task,
  we need to track the events by identity:task_uuid pair.

  Read more: https://github.com/commanded/commanded/blob/master/guides/Commands.md#custom-aggregate-identity
  """
  @enforce_keys [:hashed_identity, :task_uuid]
  defstruct [:hashed_identity, :task_uuid]

  alias Uptight.Text

  alias ZhrDevs.Submissions.SubmissionIdentity

  @type t :: %{
          :__struct__ => __MODULE__,
          required(:hashed_identity) => Uptight.Base.Urlsafe.t(),
          required(:task_uuid) => Text.t()
        }

  @spec new(keyword()) :: t()
  def new(opts) do
    opts
    |> Enum.into(%{})
    |> then(&struct!(SubmissionIdentity, &1))
  end

  defimpl String.Chars do
    @spec to_string(ZhrDevs.Submissions.SubmissionIdentity.t()) :: nonempty_binary
    def to_string(%SubmissionIdentity{hashed_identity: hashed_identity, task_uuid: task_uuid}) do
      "#{hashed_identity}:#{task_uuid}"
    end
  end
end
