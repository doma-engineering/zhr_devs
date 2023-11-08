ExUnit.start()
ExUnit.configure(exclude: [fs: true])

Mox.defmock(ZhrDevs.MockAvailableTasks, for: ZhrDevs.Tasks.ReadModels.AvailableTasks)
Application.put_env(:zhr_devs, :available_tasks_module, ZhrDevs.MockAvailableTasks)
