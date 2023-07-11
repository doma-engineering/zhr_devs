defmodule ZhrDevs.Web.Decoder.FromUrlEncoded do
  alias ZhrDevs.Submissions.Task
  alias ZhrDevs.Submissions.Task.{Language, Integration, Library}

  alias Uptight.Text, as: T

  def call(raw_urlencoded, :task) do
    raw_urlencoded
    |> URI.decode()
    |> Jason.decode!()
    |> Enum.map(fn
      {"task_name", value} ->
        {:task_name, T.new!(value)}

      {"programming_language", value} ->
        {:programming_language, Language.from_raw!(value)}

      {"integrations", values} when is_list(values) ->
        {:integrations, Enum.map(values, &Integration.from_raw!/1)}

      {"library_stack", values} when is_list(values) ->
        {:library_stack, Enum.map(values, &Library.from_raw!/1)}
    end)
    |> then(fn fields -> struct!(Task, fields) end)
  end
end
