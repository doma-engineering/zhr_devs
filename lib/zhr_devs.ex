defmodule ZhrDevs do
  @moduledoc """
  Documentation for `ZhrDevs`.
  """

  @submissions_folder Application.compile_env!(:zhr_devs, :submission_uploads_folder)
  @harvested_tasks Application.compile_env!(:zhr_devs, :harvested_tasks_structure)

  @doc """
  Provides a blessed way of building the submission upload path.

  iex> ZhrDevs.submission_upload_path(:on_the_map, :goo, "b96a7c71-1fd5-4336-a48d-3e55a6f4fce5.zip")
  "#{@submissions_folder}/on_the_map/goo/b96a7c71-1fd5-4336-a48d-3e55a6f4fce5.zip"
  """
  def submission_upload_path(task, technology, submission_file)
      when is_atom(task) and is_atom(technology) do
    task_binary = Atom.to_string(task)
    technology_binary = Atom.to_string(technology)

    Path.join([@submissions_folder, task_binary, technology_binary, submission_file])
  end

  def submission_upload_folder(task, technology)
      when is_atom(task) and is_atom(technology) do
    task_binary = Atom.to_string(task)
    technology_binary = Atom.to_string(technology)

    Path.join([@submissions_folder, task_binary, technology_binary])
  end

  @doc """
  A blessed way of getting the task download path.
  """
  def task_download_path(%ZhrDevs.Task{} = task) do
    build_download_path(task, "task.zip")
  end

  @doc """
  A blessed way of getting the additional inputs path.
  """
  def additional_inputs_download_path(%ZhrDevs.Task{} = task) do
    build_download_path(task, "inputs.zip")
  end

  defp build_download_path(%ZhrDevs.Task{} = task, kind) do
    pwd = Path.expand(".")
    dir = Path.join([pwd | @harvested_tasks])

    dir
    |> File.ls!()
    |> lookup_download(task, kind)
    |> case do
      nil -> {:error, "Could not find #{kind} for task #{task.name}_#{task.technology}"}
      entry -> {:ok, Path.join([dir, entry])}
    end
  end

  defp lookup_download(entries, task, kind) do
    {task_binary, technology_binary} = task_to_binaries(task)

    Enum.find(entries, fn entry ->
      String.ends_with?(entry, ".zip") and
      String.contains?(entry, [task_binary, technology_binary, kind])
    end)
  end

  defp task_to_binaries(%ZhrDevs.Task{name: task, technology: technology}) do
    task_binary = Atom.to_string(task)
    technology_binary = Atom.to_string(technology)

    {task_binary, technology_binary}
  end
end
