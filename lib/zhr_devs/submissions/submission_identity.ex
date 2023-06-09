defmodule ZhrDevs.Submissions.SubmissionIdentity do
  @moduledoc """
  This module provides a way to make the composite identifier for the Submission aggregate.

  Because our business rules require that the same person can't submit more than two solutions for the same technology,
  we need to track the events by identity:technology pair.

  Read more: https://github.com/commanded/commanded/blob/master/guides/Commands.md#custom-aggregate-identity
  """
  @enforce_keys [:hashed_identity, :technology]
  defstruct [:hashed_identity, :technology]

  alias ZhrDevs.Submissions.SubmissionIdentity

  @type t :: %{
          :__struct__ => __MODULE__,
          required(:hashed_identity) => Uptight.Base.Urlsafe.t(),
          required(:technology) => atom()
        }

  def new(opts) do
    opts
    |> Enum.into(%{})
    |> then(&struct!(SubmissionIdentity, &1))
  end

  defimpl String.Chars do
    def to_string(%SubmissionIdentity{hashed_identity: hashed_identity, technology: technology}) do
      "#{hashed_identity}:#{technology}"
    end
  end
end
