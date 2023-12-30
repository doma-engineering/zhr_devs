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
  @type cmd() :: Ubuntu.Command.t()
  @type run() :: {:ok, pid()} | {:error, term()}

  @callback run(cmd()) :: run()
  @callback build(opts :: Keyword.t()) :: Uptight.Result.t()
  @callback on_success(Keyword.t()) :: :ok | {:error, system_error()}
  @callback on_failure(system_error(), Keyword.t()) :: :ok
end
