defmodule ZhrDevs.Web.Shared do
  @moduledoc false

  def redirect_to(conn, route) do
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header("location", route)
    |> Plug.Conn.halt()
  end
end
