defmodule ZhrDevs.Submissions.DelayedEmailsSender do
  @moduledoc """
  This is a process that will keep track of **unhandled** submissions during the day.
  Unhandled means that there is no check performed for the submission yet.

  When new submission is received, it will schedule the additional email in 1 hour.
  If SolutionCheckStarted or SolutionCheckCompleted is received, it will cancel the scheduled email.

  It also aggregates the submission for the particular day and send an 'email digest' of all submissions received.
  After successfull sending of the digest, it will wipe the state for the next day.
  """
  defmodule SubmissionEntry do
    @moduledoc """
    This is convenience data structure to keep track of the submissions.
    """

    @enforce_keys [
      :uuid,
      :task_name,
      :technology,
      :submission_url,
      :hashed_identity,
      :received_at
    ]
    defstruct @enforce_keys ++ [:delayed_email_ref]

    def new(submission_info) do
      struct!(__MODULE__, submission_info)
    end
  end

  require Logger

  @digest_cron Cron.new!("0 0 0 * * *")

  @type submission_info :: [
          {:received_at, DateTime.t()},
          {:uuid, Uptight.Text.t()},
          {:task_name, atom()},
          {:technology, atom()},
          {:submission_url, URI.t()},
          {:hashed_identity, Uptight.Base.Urlsafe.t()}
        ]

  alias ZhrDevs.{Email, Mailer}

  use GenServer

  # Client API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec register_submission(submission_info()) :: :ok
  def register_submission(submission_info, name \\ __MODULE__) do
    submission_entry = SubmissionEntry.new(submission_info)

    GenServer.cast(name, {:register_submission, submission_entry})
  end

  @spec unregister_submission(String.t()) :: :ok
  def unregister_submission(submission_uuid, name \\ __MODULE__) do
    GenServer.cast(name, {:unregister_submission, submission_uuid})
  end

  # Server API

  @impl GenServer
  def init(opts) do
    schedule_next_digest()

    submissions = Keyword.get(opts, :submissions, %{})

    {:ok, submissions}
  end

  @impl GenServer
  def handle_cast({:register_submission, submission_entry}, submissions) do
    delayed_email_ref =
      Process.send_after(
        self(),
        {:send_delayed_email, submission_entry.uuid},
        :timer.hours(1)
      )

    submission_entry = Map.put(submission_entry, :delayed_email_ref, delayed_email_ref)

    {:noreply, Map.put(submissions, submission_entry.uuid, submission_entry)}
  end

  def handle_cast({:unregister_submission, submission_uuid}, submissions) do
    case Map.get(submissions, submission_uuid) do
      nil ->
        {:noreply, submissions}

      submission_entry ->
        :ok = maybe_cancel_timer(submission_entry.delayed_email_ref)

        updated_entry = Map.put(submission_entry, :delayed_email_ref, nil)
        updated_submissions = Map.put(submissions, submission_uuid, updated_entry)

        {:noreply, updated_submissions}
    end
  end

  @impl GenServer
  def handle_info({:send_delayed_email, submission_uuid}, submissions) do
    case Map.get(submissions, submission_uuid) do
      nil ->
        # This should never happen, because we reset the timer, but we don't want to crash the process
        {:noreply, submissions}

      submission_entry ->
        # We are using Task.Supervisor to send the email, so we can restart the process
        # But we don't have to handle email-sending errors here
        # The ZhrDevs.EmailsSendingSupervisor will do it for us
        Task.Supervisor.start_child(
          ZhrDevs.EmailsSendingSupervisor,
          fn ->
            send_submission_notification(submission_entry)
          end,
          restart: :transient
        )

        updated_entry = Map.put(submission_entry, :delayed_email_ref, nil)
        updated_submissions = Map.put(submissions, submission_uuid, updated_entry)

        {:noreply, updated_submissions}
    end
  end

  def handle_info(:send_digest, %{}) do
    schedule_next_digest()

    Logger.info("Skipping daily digest, as there is no submissions to send.")

    {:noreply, %{}}
  end

  def handle_info(:send_digest, submissions) do
    Task.Supervisor.start_child(
      ZhrDevs.EmailsSendingSupervisor,
      fn -> send_digest(submissions) end,
      restart: :transient
    )

    schedule_next_digest()

    {:noreply, %{}}
  end

  defp maybe_cancel_timer(nil), do: :ok

  defp maybe_cancel_timer(timer_ref) do
    Process.cancel_timer(timer_ref)

    :ok
  end

  defp schedule_next_digest,
    do: Process.send_after(self(), :send_digest, Cron.until(@digest_cron))

  defp send_submission_notification(%SubmissionEntry{} = submission_entry) do
    submission_entry
    |> Enum.into(Keyword.new())
    |> Email.solution_submitted()
    |> Mailer.deliver_now!()
  end

  defp send_digest(submissions) do
    submissions
    |> Map.values()
    |> Enum.into(Keyword.new())
    |> Email.daily_digest()
    |> Mailer.deliver_now!()
  end
end
