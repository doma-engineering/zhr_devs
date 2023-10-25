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
end
