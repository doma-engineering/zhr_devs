defmodule ZhrDevs.Submissions.Task do
  @moduledoc """
  Data structure that represents a task that candidates is supposed to solve.
  """

  alias Uptight.Text, as: T
  alias Uptight.Text.Urlencoded, as: TU

  @dialyzer {:nowarn_function, [new: 0, new: 1, new: 2, new: 3]}

  import Algae

  @derive Jason.Encoder

  defdata do
    task_name :: Uptight.Text.t()
    programming_language :: Uptight.Text.t()
    integrations :: list(Uptight.Text.t()) \\ []
    library_stack :: list(Uptight.Text.t()) \\ []
  end

  @required_keys [:task_name, :programming_language]

  @spec from_uri(binary()) :: __MODULE__.t()
  def from_uri(task_from_uri) when is_binary(task_from_uri) do
    task_from_uri
    |> URI.decode()
    |> Jason.decode!(keys: :atoms!)
    |> Enum.map(fn
      {key, value} when key in @required_keys and not is_binary(value) ->
        raise "Invalid structure"

      {key, nil} ->
        {key, []}

      {key, value} when is_binary(value) ->
        {key, T.new!(value)}

      {key, values} when is_list(values) ->
        {key, Enum.map(values, &T.new!/1)}
    end)
    |> then(fn fields -> struct!(__MODULE__, fields) end)
  end

  def to_uri(%__MODULE__{} = task) do
    task
    |> Jason.encode!()
    |> T.new!()
    |> TU.new!()
  end
end
