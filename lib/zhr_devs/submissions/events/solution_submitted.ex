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
    hashed_identity: Urlsafe.new(),
    trigger_automatic_check: false
  ]
  @derive Jason.Encoder
  @enforce_keys Keyword.keys(@fields)
  defstruct [:uuid | @fields]

  @type t() :: %{
          :__struct__ => __MODULE__,
          required(:uuid) => Text.t(),
          required(:hashed_identity) => Urlsafe.t(),
          required(:task_uuid) => Text.t(),
          required(:technology) => atom(),
          required(:solution_path) => list(Text.t()),
          required(:trigger_automatic_check) => boolean()
        }

  def fields do
    @fields
  end

  def aggregate_fields do
    @fields
    |> Keyword.delete(:solution_path)
    |> Keyword.delete(:trigger_automatic_check)
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.Submissions.Events.SolutionSubmitted do
  alias ZhrDevs.Submissions.Events.SolutionSubmitted

  def decode(%SolutionSubmitted{} = event) do
    %SolutionSubmitted{
      uuid: Uptight.Text.new!(event.uuid),
      task_uuid: Uptight.Text.new!(event.task_uuid),
      hashed_identity: Uptight.Base.mk_url!(event.hashed_identity),
      technology: String.to_existing_atom(event.technology),
      solution_path: Uptight.Text.new!(event.solution_path),
      trigger_automatic_check: event.trigger_automatic_check
    }
  end
end
