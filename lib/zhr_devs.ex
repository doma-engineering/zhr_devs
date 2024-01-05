defmodule ZhrDevs do
  @moduledoc """
  Documentation for `ZhrDevs`.
  """

  @submissions_folder Application.compile_env!(:zhr_devs, :submission_uploads_folder)

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
    file_path = build_download_path(task, "task.zip")

    if File.exists?(file_path) do
      {:ok, file_path}
    else
      {:error, "Task file does not exist for task #{task.name}_#{task.technology}"}
    end
  end

  @doc """
  A blessed way of getting the additional inputs path.
  """
  def additional_inputs_download_path(%ZhrDevs.Task{} = task) do
    file_path = build_download_path(task, "additional_inputs.zip")

    if File.exists?(file_path) do
      {:ok, file_path}
    else
      {:error, "Additional inputs file does not exist for task #{task.name}_#{task.technology}"}
    end
  end

  defp build_download_path(%ZhrDevs.Task{} = task, file) do
    {task_binary, technology_binary} = task_to_binaries(task)
    pwd = Path.expand(".")

    Path.join([pwd, "priv", "tasks", task_binary, technology_binary, file])
  end

  defp task_to_binaries(%ZhrDevs.Task{name: task, technology: technology}) do
    task_binary = Atom.to_string(task)
    technology_binary = Atom.to_string(technology)

    {task_binary, technology_binary}
  end
end
