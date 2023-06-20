defmodule ZhrDevs.Submissions.Events.TaskDownloaded do
  @moduledoc """
  Represents an event that is emitted when user is allowed to download a task before the first submission.
  """
  alias Uptight.Base.Urlsafe
  alias Uptight.Text, as: T

  @fields [
    technology: nil,
    task_id: T.new(),
    hashed_identity: Urlsafe.new()
  ]
  @derive Jason.Encoder
  defstruct @fields

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_id) => T.t(),
          required(:technology) => atom()
        }

  def fields, do: @fields
end
