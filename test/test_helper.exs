ExUnit.start()

Mox.defmock(ZhrDevs.MockDocker, for: ZhrDevs.Docker)
Application.put_env(:zhr_devs, :docker_module, ZhrDevs.MockDocker)

# ZhrDevs.Tasks.ReadModels.AvailableTasks.add_task(%ZhrDevs.Task{
#   uuid: Uptight.Text.new!("1"),
#   name: :on_the_map,
#   technology: :elixir
# })
