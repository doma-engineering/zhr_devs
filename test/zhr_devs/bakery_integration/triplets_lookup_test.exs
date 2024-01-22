defmodule ZhrDevs.BakeryIntegration.TripletsLookupTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.BakeryIntegration
  alias ZhrDevs.BakeryIntegration.TripletsLookup

  alias ZhrDevs.BakeryIntegration.Impure

  import Mox

  setup_all do
    Mox.defmock(ZhrDevs.MockImpure, for: Impure)
    Application.put_env(:zhr_devs, :impure_module, ZhrDevs.MockImpure)
  end

  @task %ZhrDevs.Task{name: :on_the_map, technology: :goo}

  describe "call/1" do
    setup :verify_on_exit!

    test "with empty submissions directory - raises an exception" do
      expect(ZhrDevs.MockImpure, :our_submissions_ls, fn -> [] end)

      assert_raise BakeryIntegration.Exceptions.EmptyDirectory, fn ->
        TripletsLookup.call(@task)
      end
    end

    test "with non-empty submissions directory - returns sorted triplets" do
      ZhrDevs.MockImpure
      |> expect(:our_submissions_ls, fn ->
        Enum.shuffle([
          "on_the_map-goo-hdd111",
          "hanooy_maps-scala-hdd222",
          "hanooy_maps-rust-hdd111",
          "on_the_map-goo-hdd222",
          "hanooy_maps-rust-hdd000",
          "on_the_map-goo-hdd333"
        ])
      end)
      |> expect(:our_submissions_git_log, fn ->
        ["hdd000", "hdd111", "hdd222", "hdd333"]
      end)

      assert TripletsLookup.call(@task) == [
               "on_the_map-goo-hdd111",
               "on_the_map-goo-hdd222",
               "on_the_map-goo-hdd333"
             ]
    end
  end
end
