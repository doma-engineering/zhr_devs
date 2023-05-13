defmodule ZhrDevs.Web.AuthCallbackTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import ExUnit.CaptureLog

  import ZhrDevs.Fixtures

  import Commanded.Assertions.EventAssertions

  alias ZhrDevs.Web.AuthCallback

  alias ZhrDevs.IdentityManagement.ReadModels.Identity

  alias ZhrDevs.IdentityManagement

  alias ZhrDevs.IdentityManagement.Events.LoggedIn

  describe "successfull authentication" do
    setup do
      successful_auth = generate_successful_auth(:github)
      login_event = generate_successful_login_event(successful_auth)

      %{success: successful_auth, event: login_event}
    end

    test "with new identity - redirects to /protected", %{success: success} do
      conn = build_success_conn(success)

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/protected"]
    end

    test "with new identity - receives an event", %{success: success} do
      build_success_conn(success)
      hashed_identity = success.hashed_identity

      wait_for_event(
        ZhrDevs.App,
        LoggedIn,
        fn
          %LoggedIn{hashed_identity: %Uptight.Base.Urlsafe{encoded: ^hashed_identity}} ->
            assert hashed_identity == success.hashed_identity

          _other_concurrent_login ->
            nil
        end
      )
    end

    test "with existing identity - log successful login attempt and redirects to /protected", %{
      success: success,
      event: login
    } do
      start_supervised!({Identity, login})

      assert capture_log(fn ->
               conn = build_success_conn(success)
               assert conn.status == 302
               assert get_resp_header(conn, "location") == ["/protected"]
             end) =~ "Successful authentication attempt for #{success.hashed_identity}"
    end

    test "with exsiting identity - receives an event with updated logged_in time", %{
      success: success,
      event: login
    } do
      pid = start_supervised!({Identity, login})

      %Identity{login_at: login_at} = :sys.get_state(pid)

      build_success_conn(success)
      hashed_identity = success.hashed_identity

      assert_receive_event(
        ZhrDevs.App,
        LoggedIn,
        fn
          %LoggedIn{
            login_at: new_login_at,
            hashed_identity: %Uptight.Base.Urlsafe{encoded: ^hashed_identity}
          } ->
            refute DateTime.compare(login_at.dt, new_login_at.dt) == :eq

            :timer.sleep(20)

            assert %Identity{login_at: ^new_login_at} = :sys.get_state(pid)

          _other_concurrent_login ->
            nil
        end
      )
    end

    defp build_success_conn(success) do
      conn(:get, "/auth/github/callback")
      |> init_test_session(%{hashed_identity: success.hashed_identity})
      |> assign(:oauth, success)
      |> AuthCallback.call(%{})
    end
  end

  describe "failed authentication" do
    setup do
      %{failure: generate_failed_auth(:github)}
    end

    test "redirects to the root path", %{failure: failure} do
      conn = build_failure_conn(failure)

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/"]
    end

    test "log failed login attempt", %{failure: failure} do
      assert capture_log(fn ->
               build_failure_conn(failure)
             end) =~ "Failed authentication attempt"
    end

    defp build_failure_conn(failure) do
      conn(:get, "/auth/github/callback")
      |> assign(:oauth, failure)
      |> AuthCallback.call(%{})
    end
  end
end
