defmodule ZhrDevs.Submissions.Task do
  @moduledoc """
  Data structure that represents a task that candidates is supposed to solve.
  """

  alias Uptight.Text, as: T
  alias Uptight.Text.Urlencoded, as: TU

  @dialyzer {:nowarn_function, [new: 0, new: 1, new: 2, new: 3]}

  @supported_technologies :zhr_devs
                          |> Application.compile_env(:supported_technologies)
                          |> Enum.map(&Atom.to_string/1)

  import Algae

  @derive Jason.Encoder

  defmodule Language do
    @moduledoc "The supported language in which task is written"
    @derive Jason.Encoder
    defdata(Uptight.Text.t())

    alias Uptight.Text, as: T

    def new!(binary), do: %Language{language: T.new!(binary)}

    def from_raw!(%Language{language: language}) do
      T.un(language)
    end
  end

  defmodule Library do
    @moduledoc "The libraries used in task"
    @derive Jason.Encoder
    defdata(Uptight.Text.t())

    alias Uptight.Text, as: T

    def new!(binary), do: %Library{library: T.new!(binary)}

    def from_raw!(%Library{library: library}) do
      T.un(library)
    end
  end

  defmodule Integration do
    @moduledoc false

    alias Uptight.Text, as: T

    @derive Jason.Encoder
    defdata(Uptight.Text.t())

    def new!(binary), do: %Integration{integration: T.new!(binary)}

    def from_raw!(%Integration{integration: integration}) do
      T.un(integration)
    end
  end

  defimpl Jason.Encoder, for: [Language, Library, Integration] do
    def encode(%struct{} = value, opts) do
      value |> struct.from_raw!() |> Jason.Encode.string(opts)
    end
  end

  defdata do
    task_name :: Uptight.Text.t()
    programming_language :: Language.t()
    integrations :: list(Integration.t()) \\ []
    library_stack :: list(Library.t()) \\ []
  end

  @list_keys [:integrations, :library_stack]

  @spec new!(binary()) :: __MODULE__.t()
  def new!(task_from_uri) do
    task_from_uri
    |> URI.decode()
    |> Jason.decode!(keys: :atoms!)
    |> Enum.map(fn
      {key, nil} when key in @list_keys ->
        {key, []}

      {:task_name, value} when is_binary(value) and value != "" ->
        {:task_name, T.new!(value)}

      {:programming_language, value} when value in @supported_technologies ->
        {:programming_language, Language.new!(value)}

      {:integrations, values} when is_list(values) ->
        {:integrations, Enum.map(values, &Integration.new!/1)}

      {:library_stack, values} when is_list(values) ->
        {:library_stack, Enum.map(values, &Library.new!/1)}

      _ ->
        raise "Invalid structure"
    end)
    |> then(fn fields -> struct!(__MODULE__, fields) end)
  end

  def from_raw!(%__MODULE__{} = task) do
    task
    |> Jason.encode!()
    |> T.new!()
    |> TU.new!()
  end
end
