defmodule ZhrDevs.Web.ProtectedRouter.SubmissionTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ZhrDevs.Web.ProtectedRouter

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
                 "id" => "elixir-0-dev"
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
