defmodule ZhrDevs.EmailTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.Email

  test "solution submitted" do
    email =
      Email.solution_submitted(
        task_name: :on_the_map,
        technology: :goo,
        submission_url: "",
        hashed_identity: DomaOAuth.hash("whatever") |> Uptight.Base.mk_url!()
      )

    assert email.to === Application.get_env(:zhr_devs, :submissions_operator_email)
    assert email.from === "no-reply@zhr.dev"

    assert email.text_body =~ "on_the_map"
    assert email.text_body =~ "goo"

    assert email.html_body =~ "on_the_map"
    assert email.html_body =~ "goo"
  end
end
