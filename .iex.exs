# This file is executed each time you run `iex -S mix` in the project root.
# Usefull for adding imports and aliases to the shell.
alias ZhrDevs.Submissions
alias ZhrDevs.IdentityManagement

alias ZhrDevs.Submissions.Commands.SubmitSolution

# Following functions provided to make it easier to test events in the dev environment
# build_submission_opts = fn identity, task, solution_path ->
  # [
  #   hashed_identity: "38srzhuvtWZqg8E2TtH1Geq2vsFxC2FxW0ftN-YvF2s=",
  #   task_uuid: "7e93f0b4-bdd1-465a-a10b-be17600f1b12",
  #   technology: "goo",
  #   solution_path: "/home/nox/zhr_bakery/submissions/1.zip"
  # ]

# :sys.get_state(ZhrDevs.BakeryIntegration.Queue)
# [
#   hashed_identity: "BPLA_szi6TIEB4aeYnDQX8YS3rbVrMTpHSsSWXA=",
#   task_uuid: "504b984a-1afb-4e7b-8e75-d72afc78e0cc",
#   technology: "goo",
#   solution_path: "/home/nox/zhr_bakery/submissions/1.zip"
# ]

# ZhrDevs.App.dispatch(
#   %ZhrDevs.Submissions.Commands.CompleteCheckSolution{
#     solution_uuid: Uptight.Text.new!("47b54b5c-6aca-4592-bfb4-8faadcfd94cb"),
#     task_uuid: Uptight.Text.new!("504b984a-1afb-4e7b-8e75-d72afc78e0cc"),
#     score: %{"points" => 50}
#   }
# )

# To check actual Check aggregate state:
# Commanded.Aggregates.Aggregate.aggregate_state(ZhrDevs.App, ZhrDevs.Submissions.Aggregates.Check, solution_uuid)

### Task supporting commands ###

# To 'support' the task you need to dispatch the SupportTask command to the Task aggregate.
# Below you can find a valid command that would do just that.
# The UUID field will be generated automatically (using Commanded.UUID.uuid4()) during the command handling.
#
# ZhrDevs.Tasks.Commands.SupportTask.dispatch(technology: "goo", name: "on_the_map")

# Whenever you want to change the manual task processing to automatical one,
# you can do that by dispatching the ChangeTaskMode command:
#
# ZhrDevs.Tasks.Commands.ChangeTaskMode.dispatch(technology: "goo", name: "on_the_map", trigger_automatic_check: true)

### End Task supporting commands ###

# opts = [
#  submissions_folder: %Uptight.Text{text: "/home/nox/zhr_bakery/submissions"},
#  server_code: %Uptight.Text{text: "/home/nox/on_the_map_goo"},
#  task_uuid: %Uptight.Text{text: "ab524c15-eff7-493f-82a0-4d4fed18424e"}
# ]

# cmd = ZhrDevs.BakeryIntegration.Commands.GenMultiplayer.run(opts)

# IO.inspect(cmd)