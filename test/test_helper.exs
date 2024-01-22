ExUnit.start()
ExUnit.configure(exclude: [:flaky, fs: true])

Mox.defmock(ZhrDevs.MockAvailableTasks, for: ZhrDevs.Tasks.ReadModels.AvailableTasks)
Application.put_env(:zhr_devs, :available_tasks_module, ZhrDevs.MockAvailableTasks)

# Mox.defmock(ZhrDevs.MockImpure, for: ZhrDevs.BakeryIntegration.Impure)
# Application.put_env(:zhr_devs, :impure_module, ZhrDevs.MockImpure)
