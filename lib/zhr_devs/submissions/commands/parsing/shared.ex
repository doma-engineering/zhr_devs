defmodule ZhrDevs.Submissions.Commands.Parsing.Shared do
  @moduledoc """
  Reusable command options parsing logic
  """

  import Uptight.Assertions

  @supported_technologies Enum.map(
                            Application.compile_env(:zhr_devs, :supported_technologies),
                            &Atom.to_string/1
                          )

  def unpack_technology(opts) do
    passed_technology_downcase =
      opts
      |> Keyword.fetch!(:technology)
      |> String.downcase()

    assert passed_technology_downcase in @supported_technologies,
           "Technology #{passed_technology_downcase} is not supported"

    String.to_existing_atom(passed_technology_downcase)
  end
end
