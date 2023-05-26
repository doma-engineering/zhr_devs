defmodule ZhrDevs.Docker do
  @moduledoc """
  Behaviour wrapper for calling docker functions.
  """

  @callback zip_test(String.t()) :: boolean()

  def zip_test(solution_path), do: impl().zip_test(solution_path)

  defp impl, do: Application.get_env(:zhr_devs, :docker_module)
end
