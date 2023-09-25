defmodule ZhrDevs.Web.Plugs.DownloadSubmission do
  @moduledoc """
  Information regarding an individual submission page.
  """
  use Plug.Builder

  require Logger

  @upload_dir Application.compile_env!(:zhr_devs, :uploads_path)

  plug(Plug.Logger)
  plug(:fetch_uuid)
  plug(:send_submission)

  defp fetch_uuid(conn, _) do
    case Map.get(conn.params, "submission_uuid") do
      nil ->
        Logger.warning("Unable to fetch submission, no UUID is provided.")

        ZhrDevs.Web.Shared.redirect_to(conn, "/my")

      uuid ->
        assign(conn, :submission_uuid, uuid)
    end
  end

  defp send_submission(conn, _) do
    submission_path = submission_path(conn.assigns.submission_uuid)
    hashed_identity = get_session(conn, :hashed_identity)

    case File.exists?(submission_path) do
      true ->
        submission_filename = "submission-#{conn.assigns.submission_uuid}.zip"

        conn
        |> put_resp_content_type("application/zip")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=#{submission_filename}"
        )
        |> send_file(200, submission_path)
        |> tap(fn _ ->
          Logger.info(
            "Submission #{conn.assigns.submission_uuid} is downloaded by #{hashed_identity}"
          )
        end)

      false ->
        Logger.error(
          "Unable to fetch submission, no file is found at #{submission_path}\nAccess attempt by: #{hashed_identity}"
        )

        ZhrDevs.Web.Shared.redirect_to(conn, "/my")
    end
  end

  defp submission_path(uuid) do
    Path.join(@upload_dir, "#{uuid}.zip")
  end
end
