defmodule ZhrDevs.ProtectedRouter do
  @moduledoc """
  Router for protected resources
  """

  use Plug.Router

  get("task/:id/submission") do
    send_resp(conn, 200, "Hello World")
  end
end
