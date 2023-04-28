defmodule ZhrDevs.Web.AuthCallbackTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import ExUnit.CaptureLog

  import ZhrDevs.Fixtures

  alias ZhrDevs.Web.AuthCallback

  alias ZhrDevs.IdentityManagement.Identity

  describe "successfull authentication" do
    setup do
      %{success: generate_successful_auth(:github)}
    end

    test "with existing identity - renews login time", %{success: success} do
      pid = start_supervised!({Identity, success})
      %Identity{login_at: first_login_at} = :sys.get_state(pid)

      conn = build_success_conn(success)

      %Identity{login_at: new_login_at} = :sys.get_state(pid)

      refute first_login_at == new_login_at
      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/protected"]
    end

    test "with existing identity - log successful login attempt", %{success: success} do
      start_supervised!({Identity, success})

      assert capture_log(fn ->
               build_success_conn(success)
             end) =~ "Successful authentication attempt for #{success.hashed_identity}"
    end

    test "with new identity - spawns a new process", %{success: success} do
      assert {:error, :not_found} =
               ZhrDevs.IdentityManagement.get_identity(success.hashed_identity)

      build_success_conn(success)

      assert {:ok, pid} = ZhrDevs.IdentityManagement.get_identity(success.hashed_identity)

      assert Process.alive?(pid)
    end

    test "with new identity - log successful login attempt", %{success: success} do
      assert capture_log(fn ->
               build_success_conn(success)
             end) =~ "New identity spawned"
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
