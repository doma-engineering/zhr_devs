defmodule ZhrDevs.EmailTest do
  use ExUnit.Case, async: true
  use Bamboo.Test

  alias ZhrDevs.Email

  alias Uptight.Text, as: T

  describe "solution_submitted/1" do
    test "contains expected fields" do
      now = DateTime.utc_now()

      email =
        Email.solution_submitted(
          task_name: :on_the_map,
          technology: :goo,
          submission_url: "",
          hashed_identity: DomaOAuth.hash("whatever") |> Uptight.Base.mk_url!(),
          received_at: now
        )

      assert email.to === Application.get_env(:zhr_devs, :submissions_operator_email)
      assert email.from === "no-reply@zhr.dev"

      assert email.text_body =~ "on_the_map"
      assert email.text_body =~ "goo"
      assert email.text_body =~ to_string(now)

      assert email.html_body =~ "on_the_map"
      assert email.html_body =~ "goo"
      assert email.html_body =~ to_string(now)
    end

    test "could be delivered" do
      now = DateTime.utc_now()

      email =
        Email.solution_submitted(
          task_name: :on_the_map,
          technology: :goo,
          submission_url: "",
          hashed_identity: DomaOAuth.hash("whatever") |> Uptight.Base.mk_url!(),
          received_at: now
        )

      {:ok, _} = ZhrDevs.Mailer.deliver_now(email)

      assert_delivered_email(email)
    end
  end

  describe "daily_digest/1" do
    setup do
      now = DateTime.utc_now()
      hour_ago = DateTime.add(now, -1, :hour)
      two_hours_ago = DateTime.add(now, -2, :hour)

      submissions = [
        [
          task_name: :on_the_map,
          technology: :goo,
          submission_url: "http://whatever/uuid/download",
          hashed_identity: DomaOAuth.hash("whatever"),
          received_at: two_hours_ago
        ],
        [
          task_name: :hanooy_maps,
          technology: :rust,
          submission_url: "http://letsgetrusty/uuid/download",
          hashed_identity: DomaOAuth.hash("letsgetrusty"),
          received_at: hour_ago
        ]
      ]

      %{
        submissions: submissions,
        email: Email.daily_digest(submissions),
        hour_ago: hour_ago,
        two_hours_ago: two_hours_ago
      }
    end

    test "has valid recipients", %{email: email} do
      assert email.to === Application.get_env(:zhr_devs, :submissions_operator_email)
      assert email.from === "no-reply@zhr.dev"
    end

    test "has valid subject", %{email: email} do
      assert email.subject === "Daily submissions digest"
    end

    test "contain expected fields", %{
      email: email,
      hour_ago: hour_ago,
      two_hours_ago: two_hours_ago
    } do
      assert email.text_body =~ "on_the_map"
      assert email.text_body =~ "goo"
      assert email.text_body =~ "http://whatever/uuid/download"
      assert email.text_body =~ "letsgetrusty"
      assert email.text_body =~ "hanooy_maps"
      assert email.text_body =~ "rust"
      assert email.text_body =~ "http://letsgetrusty/uuid/download"
      assert email.text_body =~ to_string(hour_ago)
      assert email.text_body =~ to_string(two_hours_ago)
    end

    test "contain expected html", %{
      email: email,
      hour_ago: hour_ago,
      two_hours_ago: two_hours_ago
    } do
      assert email.html_body =~ "on_the_map"
      assert email.html_body =~ "goo"
      assert email.html_body =~ "http://whatever/uuid/download"
      assert email.html_body =~ "letsgetrusty"
      assert email.html_body =~ "hanooy_maps"
      assert email.html_body =~ "rust"
      assert email.html_body =~ "http://letsgetrusty/uuid/download"
      assert email.html_body =~ to_string(hour_ago)
      assert email.html_body =~ to_string(two_hours_ago)
    end

    test "could be delivered", %{email: email} do
      {:ok, _} = ZhrDevs.Mailer.deliver_now(email)

      assert_delivered_email(email)
    end
  end

  describe "automatic_check_failed/1" do
    alias ZhrDevs.BakeryIntegration.Queue.RunningCheck

    setup do
      running_check = %RunningCheck{
        task_technology: "on_the_map_goo",
        solution_uuid: T.new!(Commanded.UUID.uuid4()),
        restart_opts: []
      }

      system_error = %{
        error: :execution_stopped,
        exit_status: 137,
        context: "container exited with code 137"
      }

      email =
        Email.automatic_check_failed(running_check: running_check, system_error: system_error)

      %{email: email, check: running_check}
    end

    test "contains expected text", %{email: email, check: check} do
      assert email.text_body =~ "Automatic check for on_the_map_goo has failed 3 times."
      assert email.text_body =~ "Error: :execution_stopped"
      assert email.text_body =~ "Exit_status: 137"
      assert email.text_body =~ "Context: \"container exited with code 137\""
      assert email.text_body =~ "Triggered by solution with UUID: #{check.solution_uuid}"
    end

    test "contains expected html", %{email: email, check: check} do
      assert email.html_body =~ "Automatic check for on_the_map_goo has failed 3 times."
      assert email.html_body =~ "Error: :execution_stopped"
      assert email.html_body =~ "Exit_status: 137"
      assert email.html_body =~ "Context: \"container exited with code 137\""
      assert email.html_body =~ "Triggered by solution with UUID: #{check.solution_uuid}"
    end

    test "could be delivered", %{email: email} do
      {:ok, _} = ZhrDevs.Mailer.deliver_now(email)

      assert_delivered_email(email)
    end
  end
end
