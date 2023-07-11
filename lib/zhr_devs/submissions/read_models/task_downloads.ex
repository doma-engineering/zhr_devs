defmodule ZhrDevs.Submissions.ReadModels.TaskDownloads do
  @moduledoc """
  This read-model is for global view on how many task and test cases downloads happens over time
  """

  @typep task_id :: String.t()
  @typep downloads :: %{
           task: non_neg_integer(),
           test_cases: non_neg_integer()
         }
  @typep download_kind :: :task | :test_cases

  @typep tasks :: %{task_id() => downloads()}

  @type t :: %{
          __struct__: __MODULE__,
          tasks: tasks
        }

  @default_counters %{task: 0, test_cases: 0}

  @supported_kinds Map.keys(@default_counters)

  defstruct tasks: %{}

  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec increment_downloads(task_id(), download_kind()) :: :ok
  def increment_downloads(task_id, download_kind) when download_kind in @supported_kinds do
    GenServer.call(__MODULE__, {:increment, task_id, download_kind})
  end

  @spec get_downloads() :: tasks()
  def get_downloads do
    GenServer.call(__MODULE__, :get_downloads)
  end

  ## Callbacks ##

  @impl GenServer
  def init([]) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call({:increment, task_id, download_kind}, _from, state) do
    {:reply, :ok, do_increment(state, task_id, download_kind)}
  end

  def handle_call(:get_downloads, _from, state) do
    {:reply, state.tasks, state}
  end

  defp do_increment(state, task_id, download_kind) do
    updated_downloads =
      state.tasks
      |> Map.get(task_id)
      |> do_update_downloads(download_kind)

    tasks = Map.put(state.tasks, task_id, updated_downloads)

    %__MODULE__{tasks: tasks}
  end

  defp do_update_downloads(nil, download_kind) do
    Map.update!(@default_counters, download_kind, &(&1 + 1))
  end

  defp do_update_downloads(existing_counters, download_kind) do
    Map.update!(existing_counters, download_kind, &(&1 + 1))
  end
end
