defmodule ZhrDevs.Task do
  @moduledoc """
  This module is responsible for tying together the task's:

   - UUID
   - Name
   - Technology
  """
  import Algae
  import Uptight.Assertions

  alias Uptight.Text
  alias Uptight.Result

  # The supported `technology -> [task_name]`s pairs from config.
  # It's stored as a kwlist in :zhr_devs, :task_support
  @supported Application.compile_env(:zhr_devs, :task_support)

  defprod do
    uuid :: Text.t()
    name :: :atom \\ nil
    technology :: :atom \\ nil
  end

  @spec new!(Text.t(), :atom, :atom) :: __MODULE__.t()
  def new!(uuid = %Text{}, name, technology)
      when is_atom(name) and is_atom(technology) do
    %__MODULE__{
      uuid: uuid,
      name: name,
      technology: technology
    }
  end

  @spec new(Text.t(), :atom, :atom) :: Result.possibly(__MODULE__.t())
  def new(uuid, name, technology) do
    Result.new(fn ->
      new!(uuid, name, technology)
    end)
  end

  @spec parse(binary(), binary(), binary()) :: Result.possibly(__MODULE__.t())
  def parse(uuid, name, technology) do
    Result.new(fn ->
      name = name |> String.downcase() |> String.to_existing_atom()
      technology = technology |> String.downcase() |> String.to_existing_atom()
      # Now we ensure that there is a "technology" key in @supported kwlist
      # Moreover, inside the corresponding value, there is a "name" key
      assert Keyword.get(@supported, technology),
             "Technology #{inspect(technology)} is not supported"

      new!(Text.new!(uuid), name, technology)
    end)
  end
end
