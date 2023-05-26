ExUnit.start()

Mox.defmock(ZhrDevs.MockDocker, for: ZhrDevs.Docker)
Application.put_env(:zhr_devs, :docker_module, ZhrDevs.MockDocker)
