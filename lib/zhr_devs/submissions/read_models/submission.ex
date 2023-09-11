defmodule ZhrDevs.Submissions.ReadModels.Submission do
  @moduledoc """
  Represents all submissions of user.
  """
  use GenServer

  alias ZhrDevs.Submissions.ReadModels.Submission

  alias Uptight.Text

  defstruct attempts: %{}

  # @technologies Application.compile_env(:zhr_devs, :task_support)
  @type technology() ::
          :elixir
          | :goo
          | :haskell
          | :lean
          | :typescript
          | :python
          | :rust
          | :kotlin
          | :java
          | :unity
  @type task_names() ::
          :on_the_map | :hanooy_maps | :cuake
  @type attempts_for_technology() :: %{technology() => UpToCounter.t()}
  @type t :: %{
          :__struct__ => __MODULE__,
          required(:attempts) => attempts_for_technology()
        }
  @default_counter UpToCounter.new(2, 0, true)

  alias ZhrDevs.Submissions.Events.SolutionSubmitted

  def start_link(%SolutionSubmitted{task_uuid: task_uuid} = event) do
    GenServer.start_link(__MODULE__, event, name: via_tuple(task_uuid))
  end

  @spec increment_attempts(hashed_identity :: Uptight.Base.Urlsafe.t(), Text.t()) ::
          :ok | {:error, :max_attempts_reached}
  def increment_attempts(hashed_identity, task_uuid) do
    GenServer.call(
      via_tuple(hashed_identity),
      {:increment_attempts, task_uuid}
    )
  end

  def attempts(hashed_identity) do
    GenServer.call(via_tuple(hashed_identity), :attempts)
  end

  def attempts(hashed_identity, technology) do
    GenServer.call(via_tuple(hashed_identity), {:attempts, technology})
  end

  # TODO: having a function and a static value with the same name is a bad idea
  def default_counter, do: do_extract_attempts(new_attempts())

  ### GenServer callbacks ###
  @impl GenServer
  def init(%SolutionSubmitted{task_uuid: task_uuid}) do
    # technology_atom = safe_string_to_existing_atom(technology)
    {:ok, attempts} = do_increment_attempts(new().attempts, task_uuid)

    {:ok, %__MODULE__{attempts: attempts}}
  end

  @impl GenServer
  def handle_call({:increment_attempts, task_uuid}, _from, state) do
    case do_increment_attempts(state.attempts, task_uuid) do
      {:ok, new_attempts} ->
        {:reply, :ok, %__MODULE__{state | attempts: new_attempts}}

      {:error, :max_attempts_reached} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:attempts, _from, state) do
    {:reply, do_extract_attempts(state.attempts), state}
  end

  def handle_call({:attempts, technology}, _from, state) do
    technology_atom = safe_string_to_existing_atom(technology)

    {^technology_atom, %UpToCounter{i: counter}} =
      Enum.find(state.attempts, fn {t, _} -> t == technology_atom end)

    {:reply, counter, state}
  end

  ### Private functions ###
  defp via_tuple(hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, {:submissions, to_string(hashed_identity)}}}
  end

  defp do_increment_attempts(attempts, task_uuid) do
    task_uuid_counter =
      Map.fetch(attempts, task_uuid)
      |> case do
        {:ok, y} -> y
        :error -> @default_counter
      end

    case UpToCounter.increment(task_uuid) do
      ^task_uuid_counter ->
        {:error, :max_attempts_reached}

      new_counter ->
        # If only we had a thing that returns Result<E, A>...
        {:ok, Map.put(attempts, task_uuid, new_counter)}
    end
  end

  defp do_extract_attempts(state_attempts) do
    Enum.reduce(state_attempts, [], fn {task_uuid, %UpToCounter{i: i}}, acc ->
      [%{task_uuid: task_uuid, counter: i} | acc]
    end)
  end

  defp new do
    %Submission{
      attempts: new_attempts()
    }
  end

  defp new_attempts do
    # Enum.map(@technologies, fn technology -> {technology, @default_counter} end) |> Map.new()
    %{}
  end

  defp safe_string_to_existing_atom(term) when is_binary(term) do
    String.to_existing_atom(term)
  end

  defp safe_string_to_existing_atom(term) when is_atom(term), do: term
end
