defmodule ZhrDevs.Web.ProtectedRouter.SubmissionUploadTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Mox

  alias ZhrDevs.Web.ProtectedRouter

  @routes ZhrDevs.Web.ProtectedRouter.init([])
  @test_uploads_dir Application.compile_env!(:zhr_devs, :uploads_path)
  @dummy_request_path "/task/nt/on_the_map/goo/goo-0-dev/submission"

  import ZhrDevs.Fixtures

  @task %ZhrDevs.Task{
    name: :on_the_map,
    technology: :goo,
    uuid: Uptight.Text.new!("b96a7c71-1fd5-4336-a48d-3e55a6f4fce5"),
    trigger_automatic_check: false
  }

  setup_all [:setup_dirs]

  describe "submission upload" do
    setup :verify_on_exit!

    test "allow upload with valid size" do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, 2, fn _ -> @task end)

      allowed_size = Application.get_env(:zhr_devs, :max_upload_size)
      bytes = :crypto.strong_rand_bytes(allowed_size)
      params = %{submission: generate_zip_upload_of_size(bytes)}

      conn =
        conn(:post, @dummy_request_path, params)
        |> login()
        |> ProtectedRouter.call(@routes)

      assert conn.status === 200
      assert conn.resp_body =~ "uuid4"
    end

    test "doesn't allow to upload files with invalid mime type" do
      expect(ZhrDevs.MockAvailableTasks, :get_task_by_uuid, fn _ -> @task end)

      params = %{
        submission: %Plug.Upload{
          path: "test/support/testfile.txt",
          content_type: "text/plain",
          filename: "submission.zip"
        }
      }

      conn =
        conn(:post, @dummy_request_path, params)
        |> login()
        |> ProtectedRouter.call(@routes)

      assert conn.status === 422
      assert conn.resp_body =~ "only .zip files are allowed"
    end
  end

  defp generate_zip_upload_of_size(bytes) do
    filename = "doesntmatter" <> ".zip"
    path = Path.join("/tmp/uploads", filename)

    dummy_files = [{~c"example.ex", bytes}]

    {:ok, ^path} = :zip.create(path, dummy_files)

    %Plug.Upload{
      path: path,
      content_type: "application/zip",
      filename: filename
    }
  end

  defp setup_dirs(_) do
    File.mkdir_p!(@test_uploads_dir)

    on_exit(fn ->
      File.rm_rf!("/tmp/uploads")
      File.rm_rf!(@test_uploads_dir)
    end)
  end
end
