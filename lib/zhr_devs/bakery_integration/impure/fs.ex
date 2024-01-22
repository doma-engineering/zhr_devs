defmodule ZhrDevs.BakeryIntegration.Impure.Fs do
  @moduledoc false

  alias ZhrDevs.BakeryIntegration.Impure

  @behaviour Impure

  @our_submissions_dir Application.compile_env!(:zhr_devs, :our_submissions_folder)

  @impl Impure
  def our_submissions_git_log do
    with {raw_output_string, _} <- git_log_pretty_format_short_hash() do
      raw_string_to_list(raw_output_string)
    end
  end

  @impl Impure
  def our_submissions_ls do
    with {raw_output_string, _} <- System.cmd("ls", [@our_submissions_dir]) do
      raw_string_to_list(raw_output_string)
    end
  end

  defp git_log_pretty_format_short_hash do
    System.cmd("git", ["log", "--pretty=format:'%h'"])
  end

  defp raw_string_to_list(raw_string) do
    raw_string
    |> String.replace("'", "")
    |> String.split("\n")
  end
end
