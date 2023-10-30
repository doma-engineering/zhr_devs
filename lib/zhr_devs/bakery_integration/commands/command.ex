defmodule ZhrDevs.BakeryIntegration.Commands.Command do
  @moduledoc """
  Behaviour for defining commands that can be handled correctly by the CommandRunner
  """
  @type error() :: %{
          error: atom(),
          exit_status: nil | integer(),
          context: term(),
          message: term()
        }

  @callback run(opts :: Keyword.t()) :: {:ok, pid()} | {:error, term()} | Uptight.Result.Err.t()
  @callback on_success(term()) :: :ok | {:error, term()}
  @callback on_failure(error()) :: :ok
end
