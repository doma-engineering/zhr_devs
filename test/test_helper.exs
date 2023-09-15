ExUnit.start()

Mox.defmock(ZhrDevs.MockDocker, for: ZhrDevs.Docker)
Application.put_env(:zhr_devs, :docker_module, ZhrDevs.MockDocker)

Mox.defmock(ZhrDevs.MockAvailableTasks, for: ZhrDevs.Tasks.ReadModels.AvailableTasks)
Application.put_env(:zhr_devs, :available_tasks_module, ZhrDevs.MockAvailableTasks)
