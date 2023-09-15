# This file is executed each time you run `iex -S mix` in the project root.
# Usefull for adding imports and aliases to the shell.
alias ZhrDevs.Submissions
alias ZhrDevs.IdentityManagement

alias ZhrDevs.Submissions.Commands.SubmitSolution

# Following functions provided to make it easier to test events in the dev environment
# build_submission_opts = fn identity, task, solution_path ->
#   [
#     hashed_identity: DomaOAuth.hash(identity),
#     task_uuid: DomaOAuth.hash(task),
#     technology: "elixir",
#     solution_path: solution_path
#   ]
# To check actual Check aggregate state:
# Commanded.Aggregates.Aggregate.aggregate_state(ZhrDevs.App, ZhrDevs.Submissions.Aggregates.Check, solution_uuid)

### Task supporting commands ###

# To 'support' the task you need to dispatch the SupportTask command to the Task aggregate.
# Below you can find a valid command that would do just that.
# To generate an a uuid you can use the Commanded.UUID.uuid4() function.
#
# ZhrDevs.Tasks.Commands.SupportTask.dispatch(technology: "goo", name: "on_the_map", uuid: "4e62f04b-3a3e-4650-a023-67c26f256922")

### End Task supporting commands ###
