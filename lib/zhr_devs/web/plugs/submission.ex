defmodule ZhrDevs.Web.Plugs.Submission do
  @moduledoc """
  Information regarding an individual submission page.
  """

  @behaviour Plug

  @supported_technologies :zhr_devs
                          |> Application.compile_env(:supported_technologies)
                          |> Enum.map(&Atom.to_string/1)

  import Plug.Conn

  import ZhrDevs.Web.Shared, only: [send_json: 3]

  def init([]), do: []

  def call(%{params: %{"technology" => technology}} = conn, _)
      when technology in @supported_technologies do
    send_json(conn, 200, get_details(conn, technology))
  end

  def call(conn, _opts) do
    send_json(conn, 422, %{error: "Invalid parameters", status: 422})
  end

  defp get_details(conn, technology) do
    conn
    |> get_session(:hashed_identity)
    |> ZhrDevs.Submissions.details(technology)
  end
end
