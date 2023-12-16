defmodule ZhrDevs.Email do
  @moduledoc """
  Email builder module.
  """

  import Bamboo.Email

  alias Uptight.Text, as: T

  @submissions_operator Application.compile_env!(:zhr_devs, :submissions_operator_email)

  defp noreply(to, subject, html, text) do
    new_email(
      from: "no-reply@zhr.dev",
      to: to,
      subject: subject.text,
      html_body: html.text,
      text_body: text.text
    )
  end

  @solution_submitted_subject "New solution submitted by candidate"

  def solution_submitted(opts \\ []) do
    text = submission_to_text(opts)
    html = submission_to_html(opts)

    noreply(
      @submissions_operator,
      T.new!(@solution_submitted_subject),
      T.new!(html),
      T.new!(text)
    )
  end

  def daily_digest(submissions) do
    digest_text = digest_text(submissions)
    digest_html = digest_html(submissions)

    noreply(
      @submissions_operator,
      T.new!("Daily submissions digest"),
      T.new!(digest_html),
      T.new!(digest_text)
    )
  end

  @spec submission_to_text(Keyword.t()) :: String.t()
  defp submission_to_text(submission_opts) do
    hashed_identity = submission_opts |> Keyword.fetch!(:hashed_identity) |> to_string()
    task_name = Keyword.fetch!(submission_opts, :task_name)
    technology = Keyword.fetch!(submission_opts, :technology)
    submission_url = Keyword.fetch!(submission_opts, :submission_url)
    received_at = Keyword.fetch!(submission_opts, :received_at)

    """
    Candidate's hashed identity: #{hashed_identity}
    Task: #{task_name}
    Technology: #{technology}
    Submission URL: #{submission_url}
    Received at (UTC): #{received_at}
    """
  end

  @spec submission_to_html(Keyword.t()) :: String.t()
  defp submission_to_html(submission_opts) do
    hashed_identity = submission_opts |> Keyword.fetch!(:hashed_identity) |> to_string()
    task_name = Keyword.fetch!(submission_opts, :task_name)
    technology = Keyword.fetch!(submission_opts, :technology)
    submission_url = Keyword.fetch!(submission_opts, :submission_url)
    received_at = Keyword.fetch!(submission_opts, :received_at)

    """
    <ul>
      <li>Candidate's hashed identity: #{hashed_identity}</li>
      <li>Task: #{task_name}</li>
      <li>Technology: #{technology}</li>
      <li>Received at (UTC): #{received_at}</li>
    </ul>

    <div>Click <a href="#{submission_url}">here</a> to download a submission.</div>
    """
  end

  @spec digest_text([Keyword.t()]) :: String.t()
  defp digest_text(submissions) do
    """
    Here is what we received today:

    #{Enum.map_join(submissions, "\n\n", &submission_to_text/1)}
    """
  end

  @spec digest_html([Keyword.t()]) :: String.t()
  defp digest_html(submissions) do
    """
    <h1>Here is what we received today:</h1>

    <div>
      #{Enum.map_join(submissions, "\n\n", &submission_to_html/1)}
    </div>
    """
  end
end
