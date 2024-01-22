import Config

config :zhr_devs,
  server_code_folders: %{
    {:on_the_map, :goo} => "/home/sweater/github/zerohr/tasks/on_the_map/goo"
  }

config :zhr_devs,
  submission_uploads_folder: "/tmp/submissions",
  output_json_backup_folder: "/tmp/output_backup",
  our_submissions_folder: "/tmp/zerohr/submissions/ours",
  harvested_tasks_structure: ["priv", "tasks", "harvested"],
  command_logs_folder: "/tmp/command_logs"
