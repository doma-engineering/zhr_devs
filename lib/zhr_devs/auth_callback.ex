defmodule ZhrDevs.AuthCallback do
  @moduledoc """
  This module is responsible for handling the callback from the OAuth provider.
  """

  alias DomaOAuth.Authentication.{Failure, Success}

  def call(%{assigns: %{oauth: %Success{}}} = conn, _opts), do: conn
  def call(%{assigns: %{oauth: %Failure{}}} = conn, _opts), do: conn
end
