defmodule ZhrDevs.BakeryIntegration.Commands.Command do
  @moduledoc """
  Behaviour for defining commands that can be handled correctly by the CommandRunner
  """
  @type system_error() :: %{
          error: atom(),
          exit_status: nil | integer(),
          context: term(),
          message: term()
        }

  @callback run(opts :: Keyword.t()) :: {:ok, pid()} | {:error, term()}
  @callback build(opts :: Keyword.t()) :: Uptight.Result.t()
  @callback on_success(term()) :: :ok | {:error, term()}
  @callback on_failure(system_error()) :: :ok
end
