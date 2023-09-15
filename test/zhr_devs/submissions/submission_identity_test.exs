defmodule ZhrDevs.Submissions.SubmissionIdentityTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias Uptight.Text

  alias ZhrDevs.Submissions.SubmissionIdentity

  import ZhrDevs.Fixtures

  describe "to_string/1" do
    test "returns a string representation of the identity" do
      %Uptight.Base.Urlsafe{encoded: encoded} =
        hashed_identity = identity_generator() |> DomaOAuth.hash() |> Uptight.Base.mk_url!()

      %Text{text: text} = random_uuid = Commanded.UUID.uuid4() |> Text.new!()

      identity = SubmissionIdentity.new(hashed_identity: hashed_identity, task_uuid: random_uuid)

      assert "#{encoded}:#{text}" == Kernel.to_string(identity)
    end
  end

  describe "new/1" do
    test "with valid opts - builds a struct correctly" do
      random_uuid = Commanded.UUID.uuid4()

      assert %SubmissionIdentity{hashed_identity: "hashed_identity", task_uuid: ^random_uuid} =
               SubmissionIdentity.new(hashed_identity: "hashed_identity", task_uuid: random_uuid)
    end

    test "with invalid opts - raises an error" do
      assert_raise KeyError, fn ->
        SubmissionIdentity.new(invalid: "opts")
      end
    end
  end
end
