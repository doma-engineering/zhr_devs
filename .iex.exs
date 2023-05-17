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
