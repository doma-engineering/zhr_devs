defmodule ZhrDevs.Web.ProtectedRouter.SubmissionTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ZhrDevs.Web.ProtectedRouter

  @routes ZhrDevs.Web.ProtectedRouter.init([])

  import ZhrDevs.Fixtures, only: [login: 1]
  import Mox

  describe "call/2" do
    setup :verify_on_exit!

    test "displays information if technology is supported" do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_name_technology, fn _, _ ->
        %ZhrDevs.Task{
          name: :on_the_map,
          technology: :goo,
          uuid: "goo-0-dev"
        }
      end)

      conn =
        conn(:get, "/submission/nt/on_the_map/goo")
        |> login()
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
