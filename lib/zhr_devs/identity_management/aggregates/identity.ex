defmodule ZhrDevs.IdentityManagement.Aggregates.Identity do
  @moduledoc """
  An aggregate is comprised of its state, public command functions, and state mutators.

  In a CQRS application all state must be derived from the published domain events.
  This prevents tight coupling between aggregate instances, such as querying for their state, and ensures their state isn't exposed.

  Command functions (execute/2):
    A command function receives the aggregate's state and the command to execute. It must return the resultant domain events, which may be one event or multiple events.
    
    You can return a single event or a list of events: %Event{}, [%Event{}], {:ok, %Event{}}, or {:ok, [%Event{}]}.
    To respond without returning an event you can return :ok, nil or an empty list as either [] or {:ok, []}.
    For business rule violations and errors you may return an {:error, error} tagged tuple or raise an exception.

    Name your public command functions execute/2 to dispatch commands directly to the aggregate without requiring an intermediate command handler.

  State mutators (apply/2):
    The state of an aggregate can only be mutated by applying a domain event to its state.
    This is achieved by an apply/2 function that receives the state and the domain event. It returns the modified state.
    Pattern matching is used to invoke the respective apply/2 function for an event.
    These functions must never fail as they are used when rebuilding the aggregate state from its history of domain events. You cannot reject the event once it has occurred.

  Read more: https://github.com/commanded/commanded/blob/master/guides/Aggregates.md
  """

  import Algae

  defdata do
    identity :: Uptight.Text.t()
    hashed_identity :: Uptight.Base.Urlsafe.t()
    login_at :: UtcDateTime.t()
  end

  alias ZhrDevs.IdentityManagement.Aggregates.Identity
  alias ZhrDevs.IdentityManagement.{Commands, Events}

  def execute(%Identity{}, %Commands.Login{} = login_command) do
    %Events.LoggedIn{
      identity: login_command.identity,
      hashed_identity: login_command.hashed_identity,
      login_at: UtcDateTime.new()
    }
  end

  def apply(%Identity{} = identity, %Events.LoggedIn{} = logged_in) do
    %Identity{identity | login_at: logged_in.login_at}
  end
end
