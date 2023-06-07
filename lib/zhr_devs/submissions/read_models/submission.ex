defmodule ZhrDevs.Submissions.ReadModels.Submission do
  @moduledoc """
  Represents all submissions of user.
  """
  use GenServer

  alias ZhrDevs.Submissions.ReadModels.Submission

  defstruct attempts: %{}

  @technologies Application.compile_env(:zhr_devs, :supported_technologies)
  @type technology() ::
          :elixir | :haskell | :lean | :typescript | :python | :rust | :kotlin | :java
  @type attempts_for_technology() :: %{technology() => UpToCounter.t()}
  @type t :: %{
          :__struct__ => __MODULE__,
          required(:attempts) => attempts_for_technology()
        }

  alias ZhrDevs.Submissions.Events.SolutionSubmitted

  def start_link(%SolutionSubmitted{hashed_identity: hashed_identity} = event) do
    GenServer.start_link(__MODULE__, event, name: via_tuple(hashed_identity))
  end

  @spec increment_attempts(hashed_identity :: Uptight.Base.Urlsafe.t(), String.t()) ::
          :ok | {:error, :max_attempts_reached}
  def increment_attempts(hashed_identity, technology) do
    technology_atom = safe_string_to_existing_atom(technology)

    GenServer.call(via_tuple(hashed_identity), {:increment_attempts, technology_atom})
  end

  def attempts(hashed_identity) do
    GenServer.call(via_tuple(hashed_identity), :attempts)
  end

  ### GenServer callbacks ###
  @impl GenServer
  def init(%SolutionSubmitted{technology: technology}) do
    technology_atom = safe_string_to_existing_atom(technology)
    {:ok, attempts} = do_increment_attempts(new().attempts, technology_atom)

    {:ok, %__MODULE__{attempts: attempts}}
  end

  @impl GenServer
  def handle_call({:increment_attempts, technology}, _from, state) do
    case do_increment_attempts(state.attempts, technology) do
      {:ok, new_attempts} ->
        {:reply, :ok, %__MODULE__{state | attempts: new_attempts}}

      {:error, :max_attempts_reached} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:attempts, _from, state) do
    {:reply, do_extract_attempts(state.attempts), state}
  end

  ### Private functions ###
  defp via_tuple(hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, {:submissions, to_string(hashed_identity)}}}
  end

  defp do_increment_attempts(attempts, technology_atom) do
    tech_counter = Map.fetch!(attempts, technology_atom)

    case UpToCounter.increment(tech_counter) do
      ^tech_counter ->
        {:error, :max_attempts_reached}

      new_counter ->
        {:ok, Map.put(attempts, technology_atom, new_counter)}
    end
  end

  defp do_extract_attempts(state_attempts) do
    Enum.reduce(state_attempts, %{}, fn {technology, %UpToCounter{i: i}}, acc ->
      Map.put(acc, technology, i)
    end)
  end

  @default_counter UpToCounter.new(2, 0, true)

  defp new do
    %Submission{
      attempts: new_attempts()
    }
  end

  defp new_attempts do
    Enum.map(@technologies, fn technology -> {technology, @default_counter} end) |> Map.new()
  end

  defp safe_string_to_existing_atom(term) when is_binary(term) do
    String.to_existing_atom(term)
  end

  defp safe_string_to_existing_atom(term) when is_atom(term), do: term
end
