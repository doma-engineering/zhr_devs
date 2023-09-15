defmodule ZhrDevs.IdentityManagement do
  @moduledoc """
  This module is responsible for managing identities of users.
  """

  alias ZhrDevs.IdentityManagement.ReadModels.Identity

  alias ZhrDevs.IdentityManagement.Events.LoggedIn

  def spawn_identity(%LoggedIn{} = logged_in_event) do
    DynamicSupervisor.start_child(ZhrDevs.DynamicSupervisor, {Identity, logged_in_event})
  end

  def get_identity(%Uptight.Base.Urlsafe{} = hashed_identity) do
    case Registry.lookup(ZhrDevs.Registry, {:identity, hashed_identity}) do
      [{pid, _}] when is_pid(pid) ->
        {:ok, pid}

      _ ->
        {:error, :not_found}
    end
  end
end
