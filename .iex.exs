# This file is executed each time you run `iex -S mix` in the project root.
# Usefull for adding imports and aliases to the shell.
alias ZhrDevs.Submissions
alias ZhrDevs.IdentityManagement

alias ZhrDevs.Submissions.Commands.SubmitSolution

alias Uptight.Text, as: T
alias Uptight.Text.Urlencoded, as: TU

alias ZhrDevs.Submissions

# Following functions provided to make it easier to test events in the dev environment
# build_submission_opts = fn identity, task, solution_path ->
#   [
#     hashed_identity: DomaOAuth.hash(identity),
#     task_id: "onthemap-elixir-algae-witchcraft-uptight",
#     technology: "elixir",
#     solution_path: solution_path
#   ]
# To check actual Check aggregate state:
# Commanded.Aggregates.Aggregate.aggregate_state(ZhrDevs.App, ZhrDevs.Submissions.Aggregates.Check, solution_uuid)
