defmodule ZhrDevs.Submissions.ReadModels.CandidateAttempts do
  @moduledoc """
  Represents all submissions of user.
  """
  use GenServer

  alias ZhrDevs.Submissions.ReadModels.CandidateAttempts

  alias ZhrDevs.Tasks.ReadModels.AvailableTasks

  defstruct attempts: %{}

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
  @type attempts_for_technology() :: %{ZhrDevs.Task.t() => UpToCounter.t()}
  @type t :: %{
          :__struct__ => __MODULE__,
          required(:attempts) => attempts_for_technology()
        }
  @default_counter UpToCounter.new(2, 0, true)

  alias ZhrDevs.Submissions.Events.SolutionSubmitted

  def start_link(%SolutionSubmitted{} = event) do
    GenServer.start_link(__MODULE__, event, name: via_tuple(event.hashed_identity))
  end

  @spec increment_attempts(hashed_identity :: Uptight.Base.Urlsafe.t(), ZhrDevs.Task.t()) ::
          :ok | {:error, :max_attempts_reached}
  def increment_attempts(hashed_identity, %ZhrDevs.Task{} = task) do
    GenServer.call(
      via_tuple(hashed_identity),
      {:increment_attempts, task}
    )
  end

  def attempts(hashed_identity) do
    GenServer.call(via_tuple(hashed_identity), :attempts)
  end

  def attempts(hashed_identity, %ZhrDevs.Task{} = task) do
    GenServer.call(via_tuple(hashed_identity), {:attempts, task})
  end

  def default_attempts, do: do_extract_attempts(new_attempts())

  def default_counter do
    @default_counter
  end

  ### GenServer callbacks ###
  @impl GenServer
  def init(%SolutionSubmitted{task_uuid: task_uuid}) do
    task = AvailableTasks.get_task_by_uuid(task_uuid)

    {:ok, attempts} = do_increment_attempts(new().attempts, task)

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

  def handle_call({:attempts, task}, _from, state) do
    case Map.get(state.attempts, task) do
      %UpToCounter{i: counter} ->
        {:reply, counter, state}

      nil ->
        {:reply, 0, state}
    end
  end

  ### Private functions ###
  defp via_tuple(%Uptight.Base.Urlsafe{} = hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, {:submissions, hashed_identity}}}
  end

  defp do_increment_attempts(attempts, task) do
    task_uuid_counter =
      Map.fetch(attempts, task)
      |> case do
        {:ok, y} -> y
        :error -> @default_counter
      end

    case UpToCounter.increment(task_uuid_counter) do
      ^task_uuid_counter ->
        {:error, :max_attempts_reached}

      new_counter ->
        # If only we had a thing that returns Result<E, A>...
        {:ok, Map.put(attempts, task, new_counter)}
    end
  end

  # It's so hard to type lists ffs
  @spec do_extract_attempts(attempts :: attempts_for_technology()) :: list()
  def do_extract_attempts(state_attempts) do
    Enum.reduce(state_attempts, [], fn {task, %UpToCounter{i: i}}, acc ->
      [%{task: task, counter: i} | acc]
    end)
  end

  defp new do
    %CandidateAttempts{
      attempts: new_attempts()
    }
  end

  defp new_attempts do
    AvailableTasks.get_available_tasks()
    |> Enum.map(fn task -> {task, @default_counter} end)
    |> Map.new()
  end
end
