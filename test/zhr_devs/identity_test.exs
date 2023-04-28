defmodule ZhrDevs.IdentityTest do
  use ExUnit.Case, async: true
  doctest ZhrDevs.IdentityManagement.Identity

  alias DomaOAuth.Authentication

  alias ZhrDevs.IdentityManagement.Identity

  describe "init" do
    test "with correct success struct - return {:ok, state} with valid types" do
      assert {:ok,
              %Identity{
                identity: %Uptight.Text{text: "johndoe@github.com"},
                hashed_identity: %Uptight.Base.Urlsafe{},
                login_at: %UtcDateTime{dt: %DateTime{}}
              }} = Identity.init(valid_auth_success())
    end

    test "with incorrect success struct - raises an a meaningful error" do
      assert_raise(Uptight.AssertionError, ~r/Parsing success struct is failed/, fn ->
        Identity.init(invalid_auth_success())
      end)
    end
  end

  defp valid_auth_success do
    %Authentication.Success{
      identity: "johndoe@github.com",
      hashed_identity: DomaOAuth.hash("johndoe@github.com")
    }
  end

  defp invalid_auth_success do
    %Authentication.Success{
      identity: "",
      hashed_identity: "!!!###"
    }
  end
end
