defmodule ZhrDevs.Web.ProtectedRouter.DownloadTaskTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ZhrDevs.Web.ProtectedRouter

  alias Uptight.Text, as: T

  @routes ZhrDevs.Web.ProtectedRouter.init([])

  import ZhrDevs.Fixtures
  import Mox

  @task %ZhrDevs.Task{
    name: :on_the_map,
    technology: :goo,
    uuid: T.new!("goo-0-dev"),
    trigger_automatic_check: false
  }

  describe "call/2" do
    setup do
      successful_auth = generate_successful_auth(:github)
      login_event = generate_successful_login_event(successful_auth)
      start_supervised!({ZhrDevs.IdentityManagement.ReadModels.Identity, login_event})

      {:ok, login_event: login_event}
    end

    test "when task file is not exists - returns a proper error", %{login_event: login_event} do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _ -> @task end)

      conn =
        conn(:get, "/tasks/goo-0-dev/download")
        |> Plug.Test.init_test_session(%{hashed_identity: to_string(login_event.hashed_identity)})
        |> ProtectedRouter.call(@routes)

      assert conn.status === 422

      assert %{"error" => error} = Jason.decode!(conn.resp_body)

      assert error =~ "Could not find task.zip for task on_the_map_goo"
    end

    test "when user attempts to download additional inputs without first submission attempt - return an error",
         %{login_event: login_event} do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _ -> @task end)

      conn =
        conn(:get, "/tasks/goo-0-dev/download?type=additionalInputs")
        |> Plug.Test.init_test_session(%{hashed_identity: to_string(login_event.hashed_identity)})
        |> ProtectedRouter.call(@routes)

      assert conn.status === 422

      assert %{"error" => error} = Jason.decode!(conn.resp_body)

      assert error =~ "Could not find inputs.zip for task on_the_map_goo"
    end

    test "with existing task file - returns an error when there is attempt to download additional inputs from 0 attempt",
         %{login_event: login_event} do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _ -> @task end)

      filename = create_task_file(@task, "additional_inputs.zip")

      on_exit(fn -> File.rm!(filename) end)

      conn =
        conn(:get, "/tasks/goo-0-dev/download?type=additionalInputs")
        |> Plug.Test.init_test_session(%{hashed_identity: to_string(login_event.hashed_identity)})
        |> ProtectedRouter.call(@routes)

      assert conn.status === 422

      assert %{"error" => "You can't download additional inputs for the first submission"} =
               Jason.decode!(conn.resp_body)
    end

    test "with existing task file - allows to download task", %{login_event: login_event} do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _ -> @task end)

      filename = create_task_file(@task, "task.zip")

      on_exit(fn -> File.rm!(filename) end)

      conn =
        conn(:get, "/tasks/goo-0-dev/download")
        |> Plug.Test.init_test_session(%{hashed_identity: to_string(login_event.hashed_identity)})
        |> ProtectedRouter.call(@routes)

      assert conn.status === 200
    end
  end

  defp create_task_file(%ZhrDevs.Task{technology: technology, name: name}, kind) do
    {t, n} = {Atom.to_string(technology), Atom.to_string(name)}
    path = Path.join([Path.expand("."), "priv", "tasks", "harvested", "#{t}-#{n}-#{kind}"])

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "100101101")

    path
  end
end
