defmodule ZhrDevs.Docker.Real do
  @moduledoc """
  Facade for calling real docker commands.
  """

  alias ZhrDevs.Docker.ZipTest

  def zip_test(solution_path), do: ZipTest.call(solution_path)
end
