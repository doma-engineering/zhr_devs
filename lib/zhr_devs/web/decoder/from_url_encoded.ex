defmodule ZhrDevs.Web.Decoder.FromUrlEncoded do
  @moduledoc """
  Domain-specific URLencoded strings to structs decoding
  """

  alias ZhrDevs.Submissions.Task
  alias ZhrDevs.Submissions.Task.{Integration, Language, Library}

  alias Uptight.Text, as: T

  defmodule DecodeError do
    defexception [:message]
  end

  @spec call(binary(), atom()) :: struct() | no_return()
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

      {invalid_field, _} ->
        field_not_exist!(invalid_field)
    end)
    |> then(fn fields -> struct!(Task, fields) end)
  end

  defp field_not_exist!(field) do
    raise DecodeError, "Field '#{field}' do not exists in struct."
  end
end
