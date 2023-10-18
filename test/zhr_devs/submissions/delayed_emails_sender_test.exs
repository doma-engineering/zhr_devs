defmodule ZhrDevs.Submissions.DelayedEmailsSenderTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.Submissions.DelayedEmailsSender
  alias ZhrDevs.Submissions.DelayedEmailsSender.SubmissionEntry

  import ExUnit.CaptureLog, only: [capture_log: 1]

  describe "register_submission/1" do
    setup do
      valid_submission_fields = [
        received_at: DateTime.utc_now(),
        uuid: "uuid",
        task_name: :on_the_map,
        technology: :goo,
        submission_url: "http://whatever/uuid/download",
        hashed_identity: DomaOAuth.hash("whatever")
      ]

      %{valid_fields: valid_submission_fields}
    end

    test "with valid submission fields - set the reference on individual submission to run in 1 hour",
         %{valid_fields: valid_fields} do
      pid = start_supervised!({DelayedEmailsSender, [name: __MODULE__]})

      assert :ok == DelayedEmailsSender.register_submission(valid_fields, pid)

      assert %{
               "uuid" => %SubmissionEntry{
                 delayed_email_ref: ref,
                 task_name: :on_the_map,
                 technology: :goo,
                 submission_url: "http://whatever/uuid/download"
               }
             } = :sys.get_state(pid)

      assert is_reference(ref)
      assert_in_delta(Process.cancel_timer(ref), :timer.hours(1), 250)
    end

    test "there is no way to register a submission with missing fields", %{valid_fields: fields} do
      pid = start_supervised!({DelayedEmailsSender, [name: __MODULE__]})

      for {key, _} <- fields do
        assert_raise ArgumentError, fn ->
          DelayedEmailsSender.register_submission(Keyword.drop(fields, [key]), pid)
        end
      end
    end
  end

  describe "unregister_submission/1" do
    setup do
      valid_submission_fields = [
        received_at: DateTime.utc_now(),
        uuid: "uuid",
        task_name: :on_the_map,
        technology: :goo,
        submission_url: "http://whatever/uuid/download",
        hashed_identity: DomaOAuth.hash("whatever")
      ]

      %{valid_fields: valid_submission_fields}
    end

    test "with registered submission and fresh timer - cancels the timer", %{valid_fields: f} do
      pid = start_supervised!({DelayedEmailsSender, [name: __MODULE__]})

      assert :ok == DelayedEmailsSender.register_submission(f, pid)
      assert :ok == DelayedEmailsSender.unregister_submission("uuid", pid)

      assert %{"uuid" => %SubmissionEntry{delayed_email_ref: nil}} = :sys.get_state(pid)
    end

    test "unregister is idempotent", %{valid_fields: f} do
      pid = start_supervised!({DelayedEmailsSender, [name: __MODULE__]})

      assert :ok == DelayedEmailsSender.register_submission(f, pid)
      assert :ok == DelayedEmailsSender.unregister_submission("uuid", pid)
      assert :ok == DelayedEmailsSender.unregister_submission("uuid", pid)
      assert :ok == DelayedEmailsSender.unregister_submission("uuid", pid)

      assert %{"uuid" => %SubmissionEntry{delayed_email_ref: nil}} = :sys.get_state(pid)
    end
  end

  describe "send_digest handle_info callback" do
    setup do
      state = %{
        "uuid1" => %SubmissionEntry{
          received_at: DateTime.utc_now(),
          uuid: "uuid",
          task_name: :on_the_map,
          technology: :goo,
          submission_url: "http://whatever/uuid/download",
          hashed_identity: DomaOAuth.hash("whatever")
        },
        "uuid2" => %SubmissionEntry{
          received_at: DateTime.utc_now(),
          uuid: "uuid",
          task_name: :on_the_map,
          technology: :goo,
          submission_url: "http://whatever/uuid/download",
          hashed_identity: DomaOAuth.hash("whatever")
        }
      }

      %{state: state}
    end

    test "wipes the state upon receiving the message", %{state: state} do
      pid = start_supervised!({DelayedEmailsSender, [name: __MODULE__, submissions: state]})

      assert ["uuid1", "uuid2"] = pid |> :sys.get_state() |> Map.keys()

      send(pid, :send_digest)

      assert %{} = :sys.get_state(pid)
    end

    @tag :capture_log
    test "do nothing with empty state, doesn't crash neither" do
      assert capture_log(fn ->
               pid = start_supervised!({DelayedEmailsSender, [name: __MODULE__]})

               send(pid, :send_digest)

               assert %{} = :sys.get_state(pid)
               assert Process.alive?(pid)
             end) =~ "Skipping daily digest, as there is no submissions to send."
    end
  end
end
