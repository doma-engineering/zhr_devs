defmodule ZhrDevs.IdentityManagement.EventsRouter do
  @moduledoc """
  The events router allows you to dispatch commands to other aggregates in response to domain events.

  This particular router is used to dispatch the commands in the IdentityManagement domain.
  """

  use Commanded.Commands.Router

  alias ZhrDevs.IdentityManagement.{Aggregates, Commands}

  dispatch(Commands.Login, to: Aggregates.Identity, identity: :hashed_identity)
end
