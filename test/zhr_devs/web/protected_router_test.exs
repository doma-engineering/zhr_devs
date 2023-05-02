defmodule ZhrDevs.Web.ProtectedRouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ZhrDevs.Web.ProtectedRouter

  import ZhrDevs.Fixtures

  alias ZhrDevs.IdentityManagement.ReadModels.Identity

  @routes ZhrDevs.Web.ProtectedRouter.init([])

  describe "authentication" do
    test "with authenticated identity and spawned process - do not halt the connection" do
      successful_auth = generate_successful_auth(:github)
      login_event = generate_successful_login_event(successful_auth)

      start_supervised!({Identity, login_event})

      conn =
        conn(:get, "/tasks")
        |> init_test_session(%{hashed_identity: login_event.hashed_identity.encoded})
        |> ProtectedRouter.call(@routes)

      assert conn.status === 200
      assert conn.resp_body =~ "Tasks index page!"
    end

    test "with authenticated identity and no spawned process - threat as :unauthenticated, halt connection" do
      conn =
        conn(:get, "/tasks")
        |> init_test_session(%{hashed_identity: "nonesense"})
        |> ProtectedRouter.call(@routes)

      assert conn.halted
      assert conn.status === 403
    end

    test "with no hashed_identity in session - halt the connection and redirect to /" do
      conn =
        :get
        |> conn("/tasks")
        |> ProtectedRouter.call(@routes)

      assert conn.halted
      assert conn.status === 403
    end
  end
end
