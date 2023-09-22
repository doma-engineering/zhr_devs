defmodule ZhrDevs.Web.ProtectedRouter.SubmissionTest do
  use ExUnit.Case, async: false
  use Plug.Test

  alias ZhrDevs.Submissions.ReadModels.CandidateAttempts
  alias ZhrDevs.Web.ProtectedRouter

  @routes ZhrDevs.Web.ProtectedRouter.init([])

  import ZhrDevs.Fixtures
  import Mox

  @task %ZhrDevs.Task{
    name: :on_the_map,
    technology: :goo,
    uuid: "goo-0-dev",
    trigger_automatic_check: false
  }

  setup [:set_mox_from_context, :verify_on_exit!]

  describe "call/2" do
    test "displays information if technology is supported" do
      expect(ZhrDevs.MockAvailableTasks, :get_available_tasks, fn -> [@task] end)
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_name_technology, fn _, _ -> @task end)

      successful_auth = generate_successful_auth(:github)
      login_event = generate_successful_login_event(successful_auth)

      start_supervised!({ZhrDevs.IdentityManagement.ReadModels.Identity, login_event})
      start_supervised!({CandidateAttempts, login_event.hashed_identity})

      conn =
        conn(:get, "/submission/nt/on_the_map/goo")
        |> Plug.Test.init_test_session(%{hashed_identity: to_string(login_event.hashed_identity)})
        |> ProtectedRouter.call(@routes)

      assert conn.status === 200

      assert %{
               "counter" => 0,
               "task" => %{
                 "name" => "on_the_map",
                 "technology" => "goo",
                 "uuid" => "goo-0-dev"
               },
               "invitations" => %{"invited" => [], "interested" => ["Company X"]}
             } = Jason.decode!(conn.resp_body)
    end

    test "return an error when technology is not supported" do
      conn =
        conn(:get, "/submission/javascript")
        |> login()
        |> ProtectedRouter.call(@routes)

      assert conn.status === 500
      assert conn.resp_body |> Jason.decode!() === %{"error" => "Not implemented"}
    end
  end
end
