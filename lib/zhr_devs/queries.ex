defmodule ZhrDevs.Queries do
  @moduledoc """
  Provides a set of reusable queries to be used by the application.
  """

  @doc """
  To receive all past events and be able to restore the state
  of our read models, we need to issue a following query
  that will 'reset' the corresponding subscription to the beginning of the stream.

  Call this query in the init/1 callback of the event handler
  if your read model is meant to be in-memory only.
  """
  def delete_handler_subscriptions(handler) when is_atom(handler) do
    with {:ok, connection} <- connect_to_db() do
      "Elixir." <> handler_name = Atom.to_string(handler)

      Postgrex.query!(
        connection,
        "delete from subscriptions where stream_uuid = '$all' and subscription_name = $1",
        [handler_name],
        []
      )

      GenServer.stop(connection)
    end
  end

  defp connect_to_db do
    ZhrDevs.EventStore.config()
    |> EventStore.Config.default_postgrex_opts()
    |> Postgrex.start_link()
  end
end
