defmodule ZhrDevs.Web.Shared do
  @moduledoc false

  def redirect_to(conn, route) do
    conn
    |> Plug.Conn.resp(:found, "")
    |> Plug.Conn.put_resp_header("location", route)
    |> Plug.Conn.halt()
  end

  def send_json(conn, status, json) when is_map(json) do
    Plug.Conn.send_resp(conn, status, Jason.encode!(json))
  end
end
