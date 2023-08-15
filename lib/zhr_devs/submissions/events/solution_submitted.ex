defmodule ZhrDevs.Submissions.Events.SolutionSubmitted do
  @moduledoc """
  Represents an event that is emitted when a solution is submitted.
  """

  alias Uptight.Base.Urlsafe
  alias Uptight.Text

  @fields [
    solution_path: nil,
    technology: nil,
    task_uuid: Text.new!(""),
    hashed_identity: Urlsafe.new()
  ]
  @derive Jason.Encoder
  defstruct [:uuid | @fields]

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:uuid) => Text.t(),
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_uuid) => Text.t(),
          required(:technology) => atom(),
          required(:solution_path) => list(Text.t())
        }

  def fields do
    @fields
  end

  def aggregate_fields do
    Keyword.delete(@fields, :solution_path)
  end
end
