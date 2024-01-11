defmodule ZhrDevsTest do
  use ExUnit.Case
  doctest ZhrDevs

  import Mock

  @real_world_inputs [
    "hanooy-rust-32610ca.zip",
    "on_the_map-goo-6fdcf0e",
    "hanooy-scala-d0ba0a2-inputs",
    "on_the_map-goo-6fdcf0e-inputs",
    "hanooy-scala-d0ba0a2-inputs.zip",
    "hanooy-scala-d0ba0a2.zip",
    "on_the_map-goo-6fdcf0e.zip",
    "hanooy-rust-32610ca-inputs.zip",
    "hanooy-scala-d0ba0a2",
    "hanooy-rust-32610ca",
    "on_the_map-goo-6fdcf0e-inputs.zip",
    "hanooy-rust-32610ca-inputs",
    ".gitignore"
  ]

  @task %ZhrDevs.Task{name: :on_the_map, technology: :goo}

  describe "download_task_path/2" do
    setup_with_mocks([
      {File, [], [ls!: fn _ -> @real_world_inputs end]},
      {File, [], [cwd!: fn -> "/home/zhr_devs/" end]}
    ]) do
      :ok
    end

    test "returns path to task when it exists" do
      assert {:ok, "/home/zhr_devs/priv/tasks/harvested/on_the_map-goo-6fdcf0e.zip"} =
               ZhrDevs.task_download_path(@task)
    end

    test "returns path to inputs when it exists" do
      assert {:ok, "/home/zhr_devs/priv/tasks/harvested/on_the_map-goo-6fdcf0e-inputs.zip"} =
               ZhrDevs.additional_inputs_download_path(@task)
    end
  end
end
