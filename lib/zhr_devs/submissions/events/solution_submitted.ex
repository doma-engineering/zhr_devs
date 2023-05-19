defmodule ZhrDevs.Submissions.Events.SolutionSubmitted do
  @moduledoc """
  Represents an event that is emitted when a solution is submitted.
  """

  alias Uptight.Base.Urlsafe

  @fields [
    solution_path: nil,
    technology: nil,
    task_uuid: Urlsafe.new(),
    hashed_identity: Urlsafe.new()
  ]
  @derive Jason.Encoder
  defstruct [:uuid | @fields]

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:uuid) => Urlsafe.t(),
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_uuid) => Urlsafe.t(),
          required(:technology) => atom(),
          required(:solution_path) => list(Urlsafe.t())
        }

  def fields do
    @fields
  end

  def aggregate_fields do
    Keyword.delete(@fields, :solution_path)
  end
end
