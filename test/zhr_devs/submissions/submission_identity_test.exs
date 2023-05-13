defmodule ZhrDevs.Submissions.SubmissionIdentityTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.Submissions.SubmissionIdentity

  import ZhrDevs.Fixtures

  describe "to_string/1" do
    test "returns a string representation of the identity" do
      %Uptight.Base.Urlsafe{encoded: encoded} =
        hashed_identity = identity_generator() |> DomaOAuth.hash() |> Uptight.Base.mk_url!()

      identity = SubmissionIdentity.new(hashed_identity: hashed_identity, technology: :elixir)

      assert "#{encoded}:elixir" == Kernel.to_string(identity)
    end
  end

  describe "new/1" do
    test "with valid opts - builds a struct correctly" do
      assert %SubmissionIdentity{hashed_identity: "hashed_identity", technology: :elixir} =
               SubmissionIdentity.new(hashed_identity: "hashed_identity", technology: :elixir)
    end

    test "with invalid opts - raises an error" do
      assert_raise KeyError, fn ->
        SubmissionIdentity.new(invalid: "opts")
      end
    end
  end
end
