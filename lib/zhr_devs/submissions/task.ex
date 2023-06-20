defmodule ZhrDevs.Submissions.Task do
  @moduledoc """
  Data structure that represents a task that candidates is supposed to solve.
  """

  alias Uptight.Text, as: T

  import Algae

  @derive Jason.Encoder

  defmodule Language do
    @moduledoc "The supported language in which task is written"
    defprod(Uptight.Text.t() \\ nil)

    alias Uptight.Text, as: T

    def new!(%T{} = language), do: %Language{language: language}

    def from_raw!(binary) do
      binary |> T.new!() |> new!()
    end

    defimpl Jason.Encoder, for: __MODULE__ do
      def encode(value, opts) do
        value.language
        |> T.un()
        |> Jason.Encode.string(opts)
      end
    end
  end

  defmodule Library do
    @moduledoc "The libraries used in task"
    defprod(Uptight.Text.t() \\ nil)

    alias Uptight.Text, as: T

    def new!(%T{} = library), do: %Library{library: library}

    def from_raw!(binary) do
      binary |> T.new!() |> new!()
    end

    defimpl Jason.Encoder, for: Library do
      def encode(value, opts) do
        value.library
        |> T.un()
        |> Jason.Encode.string(opts)
      end
    end
  end

  defmodule Integration do
    @moduledoc false

    alias Uptight.Text, as: T

    defprod(Uptight.Text.t() \\ nil)

    def new!(%T{} = integration), do: %Integration{integration: integration}

    def from_raw!(binary) do
      binary |> T.new!() |> new!()
    end

    defimpl Jason.Encoder, for: Integration do
      def encode(value, opts) do
        value.integration
        |> T.un()
        |> Jason.Encode.string(opts)
      end
    end
  end

  defprod do
    task_name :: Uptight.Text.t() \\ nil
    programming_language :: Language.t() \\ nil
    integrations :: list(Integration.t()) \\ []
    library_stack :: list(Library.t()) \\ []
  end

  def new!(%T{} = name, language, library_stack \\ [], integrations \\ []) do
    %__MODULE__{
      task_name: name,
      programming_language: language,
      library_stack: library_stack,
      integrations: integrations
    }
  end
end
