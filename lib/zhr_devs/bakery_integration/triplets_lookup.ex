defmodule ZhrDevs.BakeryIntegration.TripletsLookup do
  @moduledoc """
  Utility module to lookup triplets for the given task.
  """

  alias ZhrDevs.BakeryIntegration.Impure

  alias ZhrDevs.BakeryIntegration.Exceptions.EmptyDirectory

  @opaque sorted_triplet :: [String.t()]

  @doc """
  Returns triplets of name-task-hash
  sorted by git hash (from newest to oldest).
  """
  @spec call(ZhrDevs.Task.t()) :: sorted_triplet()
  def call(%ZhrDevs.Task{} = task) do
    unsorted_task_triplets = task_triplets(task)

    if unsorted_task_triplets == [] do
      raise EmptyDirectory, message: "There are no submissions for the given task"
    end

    our_submissions_git_log = Impure.our_submissions_git_log()

    Enum.reduce_while(
      our_submissions_git_log,
      {unsorted_task_triplets, []},
      &match_hash_to_triplet/2
    )
    |> then(fn {_, sorted_triplets_list} -> Enum.reverse(sorted_triplets_list) end)
  end

  defp match_hash_to_triplet(_x, {[], sorted_triplets_list}) do
    {:halt, sorted_triplets_list}
  end

  defp match_hash_to_triplet(x, {tasks, sorted_triplets_list}) do
    case Enum.split_with(tasks, fn task -> String.ends_with?(task, x) end) do
      {[], _} ->
        {:cont, {tasks, sorted_triplets_list}}

      {[task], rest} ->
        {:cont, {rest, [task | sorted_triplets_list]}}
    end
  end

  defp task_triplets(task) do
    bakery_format_taskname = "#{task.name}-#{task.technology}"

    Enum.filter(Impure.our_submissions_ls(), &String.starts_with?(&1, bakery_format_taskname))
  end
end
