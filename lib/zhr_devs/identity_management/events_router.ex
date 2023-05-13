defmodule ZhrDevs.IdentityManagement.EventsRouter do
  @moduledoc """
  The events router allows you to dispatch commands to other aggregates in response to domain events.

  This particular router is used to dispatch the commands in the IdentityManagement domain.

  There are two ways to specify the `identity` to dispatch correct events to:
  1. Use the `identify` macro: 
    identify Aggregates.Identity, by: :hashed_identity
  2. specify the :identity directly in the dispatch macro:
    dispatch(Commands.Login, to: Aggregates.Identity, identity: :hashed_identity)


  Read more about distpatching commands: https://github.com/commanded/commanded/blob/master/guides/Commands.md#command-dispatch-and-routing
  """

  use Commanded.Commands.Router

  alias ZhrDevs.IdentityManagement.{Aggregates, Commands}

  dispatch(Commands.Login, to: Aggregates.Identity, identity: :hashed_identity)
end
