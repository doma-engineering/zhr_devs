defmodule ZhrDevs.IdentityTest do
  use ExUnit.Case, async: true
  doctest ZhrDevs.IdentityManagement.ReadModels.Identity

  alias ZhrDevs.IdentityManagement.ReadModels.Identity

  import ZhrDevs.Fixtures

  describe "init" do
    test "with correct success struct - return {:ok, state} with valid types" do
      login_event = generate_successful_login_event(:github)

      assert {:ok,
              %Identity{
                identity: %Uptight.Text{},
                hashed_identity: %Uptight.Base.Urlsafe{},
                login_at: %UtcDateTime{dt: %DateTime{}}
              }} = Identity.init(login_event)
    end
  end
end
