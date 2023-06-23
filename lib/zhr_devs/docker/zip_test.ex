defmodule ZhrDevs.Docker.ZipTest do
  @moduledoc """
  This module is dumbest possible alpine zip -T implementation.

  It is not intended to be used in production.
  """
  require Logger

  @image_path "docker/zip-checker.dockerfile"

  def call(solution_path) do
    image = "zip-checker:" <> mk_tag!()

    with docker when is_binary(docker) <- System.find_executable("docker"),
         {_, 0} <- System.cmd(docker, build(solution_path, image)),
         {_, 0} <- System.cmd(docker, run(image)),
         {_, 0} <- System.cmd(docker, remove(image)) do
      true
    else
      nil ->
        Logger.error("Could not find docker executable")

        false

      {error, status_code} ->
        Logger.error(
          "Error while trying to run docker zip -T error: #{inspect(error)}, status code: #{status_code}}}"
        )

        false
    end
  end

  defp build(solution_path, image) do
    [
      "build",
      "-f",
      @image_path,
      ".",
      "-t",
      image,
      "--build-arg",
      "ZIP_PATH=#{solution_path}"
    ]
  end

  defp run(image) do
    ["run", "--rm", image]
  end

  defp remove(image) do
    ["image", "rm", "-f", image]
  end

  defp mk_tag! do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64() |> binary_part(0, 8)
  end
end
