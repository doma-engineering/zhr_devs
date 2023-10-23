defmodule ZhrDevs.BakeryIntegration.Commands.Command do
  @moduledoc """
  Behaviour for defining commands that can be handled correctly by the CommandRunner
  """
  @type error() :: %{error: atom(), message: term(), exit_status: nil | integer()}

  @callback run(opts :: Keyword.t()) :: {:ok, pid()} | {:error, term()}
  @callback on_success(term()) :: :ok | {:error, term()}
  @callback on_failure(error()) :: :ok
end
