defmodule ZhrDevs.IdentityManagement.CommandsTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  import Commanded.Assertions.EventAssertions

  import ZhrDevs.Web.Presentation.Helper, only: [extract_error: 1]

  alias ZhrDevs.App

  alias ZhrDevs.IdentityManagement.{Commands, Events}

  test "dispatch of the Login command emits an event with tighten identity, hashed_identity and login_at stamp" do
    opts = [identity: "example", hashed_identity: "sPJI3B_c0reGPtFtacqjHWDzSUh_AkkujufycDOYweI="]

    :ok = Commands.Login.dispatch(opts)

    assert_receive_event(App, Events.LoggedIn, fn event ->
      assert %{
               identity: %Uptight.Text{},
               hashed_identity: %Uptight.Base.Urlsafe{},
               login_at: %UtcDateTime{dt: %DateTime{}}
             } = event
    end)
  end

  test "new/1 will fail with invalid input" do
    opts = [identity: "example", hashed_identity: "sPJI3B_c0reGPtFtacqjHWD+SUh_AkkujufycDOYweI="]

    {:error, exception} = Commands.Login.dispatch(opts)

    assert %ArgumentError{message: "non-alphabet character found: \"+\" (byte 43)"} =
             extract_error(exception)
  end

  test "new/1 will fail with invalid options" do
    opts = [identity: "example"]

    {:error, exception} = Commands.Login.dispatch(opts)

    assert %KeyError{key: :hashed_identity} = extract_error(exception)
  end
end
