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
#   hashed_identity: "zRcB77sjpxcD8Hh9pWjq4_g5Pf3KU5g_pPxqRzcxsLQ=",
#   task_uuid: "83a16039-b846-431f-803f-c4e51a8d0cac",
#   technology: "goo",
#   solution_path: "/Users/thunderbook/Work/doma/zhr_bakery/submissions/1.zip"
# ]

# ZhrDevs.App.dispatch(
#   %ZhrDevs.Submissions.Commands.StartSolutionCheck{
#     solution_uuid: Uptight.Text.new!("3ed96175-633e-4c66-bda2-ddc35140c5d7"),
#     task_uuid: Uptight.Text.new!("83a16039-b846-431f-803f-c4e51a8d0cac"),
#     solution_path: "/Users/thunderbook/Work/doma/zhr_bakery/submissions/1.zip"
#   }
# )

# ZhrDevs.App.dispatch(
#   %ZhrDevs.Submissions.Commands.CompleteSolutionCheck{
#     solution_uuid: Uptight.Text.new!("3ed96175-633e-4c66-bda2-ddc35140c5d7"),
#     task_uuid: Uptight.Text.new!("83a16039-b846-431f-803f-c4e51a8d0cac"),
#     score: File.read!("score_example.json") |> Jason.decode!() |> Map.get("gen_multiplayer_score")
#   }
# )

# To check actual Check aggregate state:
# Commanded.Aggregates.Aggregate.aggregate_state(ZhrDevs.App, ZhrDevs.Submissions.Aggregates.Check, solution_uuid)

### Task supporting commands ###

# To 'support' the task you need to dispatch the SupportTask command to the Task aggregate.
# Below you can find a valid command that would do just that.
# The UUID field will be generated automatically (using Commanded.UUID.uuid4()) during the command handling.
#
# ZhrDevs.Tasks.Commands.SupportTask.dispatch(technology: "goo", name: "on_the_map", trigger_automatic_check: true)

# Whenever you want to change the manual task processing to automatical one,
# you can do that by dispatching the ChangeTaskMode command:
#
# ZhrDevs.Tasks.Commands.ChangeTaskMode.dispatch(technology: "goo", name: "on_the_map", trigger_automatic_check: true)

### End Task supporting commands ###

# opts = [
#  submissions_folder: %Uptight.Text{text: "/home/nix/zhr_bakery/submissions"},
#  server_code: %Uptight.Text{text: "/home/nix/on_the_map_goo"},
#  task_uuid: %Uptight.Text{text: "5b24b694-00de-4085-830e-4d8b43b5a2ef"}
# ]

# cmd = ZhrDevs.BakeryIntegration.Commands.GenMultiplayer.run(opts)

# IO.inspect(cmd)

# [{pid, _}] = Registry.lookup(ZhrDevs.Registry, {:tournament_runs, Uptight.Text.new!("83a16039-b846-431f-803f-c4e51a8d0cac")})
