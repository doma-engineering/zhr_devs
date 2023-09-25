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
      to: to.text,
      subject: subject.text,
      html_body: html.text,
      text_body: text.text
    )
  end

  @solution_submitted_subject "New solution submitted by candidate"

  def solution_submitted(opts \\ []) do
    hashed_identity = opts |> Keyword.fetch!(:hashed_identity) |> to_string()
    task_name = Keyword.fetch!(opts, :task_name)
    technology = Keyword.fetch!(opts, :technology)
    submission_url = Keyword.fetch!(opts, :submission_url)

    text = """
      Candidate's hashed identity: #{hashed_identity}
      Task: #{task_name}
      Technology: #{technology}
      Submission URL: #{submission_url}
    """

    html = """
    <ul>
      <li>Candidate's hashed identity: #{hashed_identity}</li>
      <li>Task: #{task_name}</li>
      <li>Technology: #{technology}</li>
    </ul>

    <div>Click <a href="#{submission_url}">here</a> to download a submission.</div>
    """

    noreply(
      T.new!(@submissions_operator),
      T.new!(@solution_submitted_subject),
      T.new!(html),
      T.new!(text)
    )
  end
end
