defmodule ZhrDevs.IdentityManagement.Events.LoggedIn do
  @moduledoc """
  Represents an a domain event of a user logging in.

  Domain events indicate that something of importance has occurred, within the context of an aggregate.
  They should be named in the past tense: account registered; funds transferred; fraudulent activity detected etc.

  Create a module per domain event and define the fields with defstruct. An event should contain a field to uniquely identify the aggregate instance (e.g. account_number).

  Remember to derive the Jason.Encoder protocol for the event struct to ensure JSON serialization is supported, as shown below.
  Note, due to event serialization you should expect that only: strings, numbers and boolean values defined in an event are preserved; any other value will be converted to a string. You can control this behaviour as described in the Serialization guide.
  """

  @derive Jason.Encoder
  import Algae

  defdata do
    identity :: Uptight.Text.t()
    hashed_identity :: Uptight.Base.Urlsafe.t()
    login_at :: UtcDateTime.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: ZhrDevs.IdentityManagement.Events.LoggedIn do
  alias ZhrDevs.IdentityManagement.Events.LoggedIn

  def decode(%LoggedIn{} = event) do
    %LoggedIn{
      identity: Uptight.Text.new(event.identity),
      hashed_identity: Uptight.Base.mk_url!(event.hashed_identity),
      login_at: UtcDateTime.new(event.login_at)
    }
  end
end
