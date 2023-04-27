defmodule ZhrDevs.IdentityManagement do
  @moduledoc """
  This module is responsible for managing identities of users.
  """

  alias DomaOAuth.Authentication.Success
  alias ZhrDevs.IdentityManagement.Identity

  defdelegate renew_login(hashed_identity), to: Identity

  def spawn_identity(%Success{} = success_struct) do
    DynamicSupervisor.start_child(ZhrDevs.DynamicSupervisor, {Identity, success_struct})
  end

  def get_identity(hashed_identity) do
    case Registry.lookup(ZhrDevs.Registry, hashed_identity) do
      [{pid, _}] when is_pid(pid) ->
        {:ok, pid}

      _ ->
        {:error, :not_found}
    end
  end
end
