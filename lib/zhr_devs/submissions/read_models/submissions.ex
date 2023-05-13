defmodule ZhrDevs.Submissions.ReadModels.Submissions do
  @moduledoc """
  Represents all submissions of user.
  """
  use GenServer

  defstruct attempts: %{}

  alias ZhrDevs.Submissions.Events.SolutionSubmitted

  def start_link(%SolutionSubmitted{hashed_identity: hashed_identity} = event) do
    GenServer.start_link(__MODULE__, event, name: via_tuple(hashed_identity))
  end

  def increment_attempts(hashed_identity, technology) do
    GenServer.call(via_tuple(hashed_identity), {:increment_attempts, technology})
  end

  def attempts(hashed_identity) do
    GenServer.call(via_tuple(hashed_identity), :attempts)
  end

  ### GenServer callbacks ###
  @impl GenServer
  def init(%SolutionSubmitted{technology: technology}) do
    {:ok, %__MODULE__{attempts: %{technology => 1}}}
  end

  @impl GenServer
  def handle_call({:increment_attempts, technology}, _from, state) do
    attempts = Map.update(state.attempts, technology, 1, &(&1 + 1))
    {:reply, :ok, %__MODULE__{state | attempts: attempts}}
  end

  def handle_call(:attempts, _from, state) do
    {:reply, state.attempts, state}
  end

  ### Private functions ###
  defp via_tuple(hashed_identity) do
    {:via, Registry, {ZhrDevs.Registry, {:submissions, to_string(hashed_identity)}}}
  end
end
