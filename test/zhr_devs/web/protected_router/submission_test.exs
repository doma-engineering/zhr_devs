defmodule ZhrDevs.Web.ProtectedRouter.SubmissionTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ZhrDevs.Web.ProtectedRouter

  @raw_task_id "%7B%22task_name%22%3A%22onTheMap%22%2C%22programming_language%22%3A%22elixir%22%2C%22library_stack%22%3A%5B%22ecto%22%2C%22postgresql%22%5D%2C%22integrations%22%3A%5B%5D%7D"
  @routes ZhrDevs.Web.ProtectedRouter.init([])

  import ZhrDevs.Fixtures, only: [login: 1]

  describe "call/2" do
    test "displays information if technology is supported" do
      conn =
        conn(:get, "/submission/elixir")
        |> login()
        |> ProtectedRouter.call(@routes)

      assert conn.status === 200

      assert %{
               "counter" => 0,
               "task" => %{
                 "id" => @raw_task_id
               },
               "technology" => "elixir",
               "invitations" => %{"invited" => [], "interested" => ["Company X"]}
             } = Jason.decode!(conn.resp_body)
    end

    test "return an error when technology is not supported" do
      conn =
        conn(:get, "/submission/javascript")
        |> login()
        |> ProtectedRouter.call(@routes)

      assert conn.status === 422
      assert %{"error" => "Invalid params", "status" => 422}
    end
  end
end
