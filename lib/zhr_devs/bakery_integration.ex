defmodule ZhrDevs.BakeryIntegration do
  @moduledoc """
  The `zhr_bakery` is a set of Rust scripts that automate business processes and runs stuff using Docker.

  We don't using NIF's for talk to Rust, instead we using Port's.
  ZhrDevs.BakeryIntegration.CommandRunner is the module that abstracts the running process
  (essentially listening to the port and process the output)

  When we are talking about high resource consuming scripts (such as GenMultiplayer),
  we usually don't want to run all past and incoming checks right away because the system will be too busy
  creating a bunch of containers for each submission and running all them together.

  We buffer the incoming submissions instead, through the Queue process
  """

  alias ZhrDevs.BakeryIntegration.Commands.Command
  alias ZhrDevs.BakeryIntegration.Commands.GenMultiplayer

  @typedoc """
  For now it will be just Ubuntu.Command.t()
  And it became this type below when Logger PR will be merged
  """
  @type command_with_metadata() :: [{:cmd, Command.cmd()}, {:logger_metadata, Keyword.t()}]

  @spec run_command(Ubuntu.Command.t()) :: Command.run()
  def run_command(command_options) do
    DynamicSupervisor.start_child(
      ZhrDevs.Submissions.CheckSupervisor,
      {ZhrDevs.BakeryIntegration.CommandRunner, command_options}
    )
  end

  @doc """
  We want different tasks to trigger different commands.
  One type of tasks require OTMG, such as 'on_the_map' task.
  Others will require SinglePlayer command or something.
  """
  def command_module(%ZhrDevs.Task{name: :on_the_map}) do
    GenMultiplayer
  end
end
