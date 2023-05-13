defmodule ZhrDevs.Submissions.ReadModels.UpToCounter do
  @moduledoc """
  Represents all submissions of user.
  """
  use GenServer

  alias ZhrDevs.Submissions.ReadModels.UpToCounter

  defstruct attempts: %{}

  @typep technology() ::
           :elixir | :haskell | :lean | :typescript | :python | :rust | :kotlin | :java
  @typep attempts_for_technology() :: %{technology() => integer()}
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
    technology_atom = String.to_existing_atom(technology)

    GenServer.call(via_tuple(hashed_identity), {:increment_attempts, technology_atom})
  end

  def attempts(hashed_identity) do
    GenServer.call(via_tuple(hashed_identity), :attempts)
  end

  ### GenServer callbacks ###
  @impl GenServer
  def init(%SolutionSubmitted{technology: technology}) do
    technology_atom = String.to_existing_atom(technology)
    attempts = do_increment_attempts(new().attempts, technology_atom)

    {:ok, %__MODULE__{attempts: attempts}}
  end

  @impl GenServer
  def handle_call({:increment_attempts, technology}, _from, state) do
    case Map.get(state.attempts, technology) do
      allowed_attempts when allowed_attempts < 2 ->
        attempts = do_increment_attempts(state.attempts, technology)

        {:reply, :ok, %__MODULE__{state | attempts: attempts}}

      _ ->
        {:reply, {:error, :max_attempts_reached}, state}
    end
  end

  def handle_call(:attempts, _from, state) do
    {:reply, state.attempts, state}
  end

  ### Private functions ###
  defp via_tuple(hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, {:submissions, to_string(hashed_identity)}}}
  end

  defp do_increment_attempts(attempts, technology_atom) do
    Map.update!(attempts, technology_atom, &(&1 + 1))
  end

  defp new() do
    %UpToCounter{
      attempts: %{
        :elixir => 0,
        :haskell => 0,
        :lean => 0,
        :typescript => 0,
        :python => 0,
        :rust => 0,
        :kotlin => 0,
        :java => 0
      }
    }
  end
end
