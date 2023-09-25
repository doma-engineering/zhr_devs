defmodule ZhrDevs.Task do
  @moduledoc """
  This module is responsible for tying together the task's:

   - UUID
   - Name
   - Technology
   - Mode of task processing (manual or automatic).
    With manual mode we are not trying to evaluate the solution automatically,
    instead we just notify the operator that the submission is arrived.

    All tasks are in manual mode by default.
  """
  import Algae
  import Uptight.Assertions

  alias Uptight.Result
  alias Uptight.Text

  # The supported `technology -> [task_name]`s pairs from config.
  # It's stored as a kwlist in :zhr_devs, :task_support
  @supported Application.compile_env!(:zhr_devs, :task_support)

  @derive {Jason.Encoder, except: [:trigger_automatic_check]}
  defprod do
    uuid :: Text.t()
    name :: atom() \\ nil
    technology :: atom() \\ nil
    trigger_automatic_check :: boolean() \\ false
  end

  @spec new!(Text.t(), atom(), atom(), boolean()) :: __MODULE__.t()
  def new!(uuid = %Text{}, name, technology, trigger_automatic_check \\ false)
      when is_atom(name) and is_atom(technology) do
    %__MODULE__{
      uuid: uuid,
      name: name,
      technology: technology,
      trigger_automatic_check: trigger_automatic_check
    }
  end

  @spec new(Text.t(), atom(), atom()) :: Result.possibly(__MODULE__.t())
  def new(uuid, name, technology, trigger_automatic_check \\ false) do
    Result.new(fn ->
      new!(uuid, name, technology, trigger_automatic_check)
    end)
  end

  @spec parse(binary(), binary(), binary(), boolean()) :: Result.possibly(__MODULE__.t())
  def parse(uuid, name, technology, trigger_automatic_check \\ false) do
    Result.new(fn ->
      name = name |> String.downcase() |> String.to_existing_atom()
      technology = technology |> String.downcase() |> String.to_existing_atom()
      # Now we ensure that there is a "technology" key in @supported kwlist
      # Moreover, inside the corresponding value, there is a "name" key
      assert Keyword.get(@supported, technology),
             "Technology #{inspect(technology)} is not supported"

      new!(Text.new!(uuid), name, technology, trigger_automatic_check)
    end)
  end
end
