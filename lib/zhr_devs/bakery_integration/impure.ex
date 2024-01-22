defmodule ZhrDevs.BakeryIntegration.Impure do
  @moduledoc false

  @callback our_submissions_git_log() :: list(String.t())
  @callback our_submissions_ls() :: list(String.t())

  def our_submissions_git_log do
    impl().our_submissions_git_log()
  end

  def our_submissions_ls do
    impl().our_submissions_ls()
  end

  defp impl,
    do:
      Application.get_env(
        :zhr_devs,
        :impure_module,
        ZhrDevs.BakeryIntegration.Impure.Fs
      )
end
