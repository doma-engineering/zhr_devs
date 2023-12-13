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

  @type options() :: [
          {:cmd, Ubuntu.Command.t()},
          {:on_success, (() -> :ok | {:error, term()})},
          {:on_failure, (() -> :ok)}
        ]

  @type run() :: {:ok, pid()} | {:error, term()}

  @callback run(opts :: Keyword.t()) :: run()
  @callback build(opts :: Keyword.t()) :: Uptight.Result.t()
  @callback on_success(term()) :: :ok | {:error, term()}
  @callback on_failure(system_error()) :: :ok
end
