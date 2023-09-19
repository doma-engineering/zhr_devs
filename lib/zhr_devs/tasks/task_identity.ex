defmodule ZhrDevs.Tasks.TaskIdentity do
  @moduledoc """
  This module provides a way to make the composite identifier for the Task aggregate.

  As we agreed, the individual task is identified by the name and technology.

  Read more: https://github.com/commanded/commanded/blob/master/guides/Commands.md#custom-aggregate-identity
  """
  @enforce_keys [:name, :technology]
  defstruct @enforce_keys

  alias __MODULE__

  @type t :: %{
          :__struct__ => __MODULE__,
          required(:name) => atom(),
          required(:technology) => atom()
        }

  @spec new(keyword()) :: t()
  def new(opts) do
    opts
    |> Enum.into(%{})
    |> then(&struct!(TaskIdentity, &1))
  end

  defimpl String.Chars do
    @spec to_string(TaskIdentity.t()) :: nonempty_binary
    def to_string(%TaskIdentity{name: name, technology: technology}) do
      "#{name}:#{technology}"
    end
  end
end
