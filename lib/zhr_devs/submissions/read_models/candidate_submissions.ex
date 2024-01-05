defmodule ZhrDevs.Submissions.ReadModels.CandidateSubmissions do
  @moduledoc """
  This read model is used to keep track of all submissions made by candidates,
  so that we can display and filter them in the admin panel.
  """

  @type register_submission_opts() :: [
          task: String.t(),
          hashed_identity: Uptight.Text.t(),
          submission_uuid: Uptight.Text.t()
        ]

  @table_name :candidate_submissions

  use GenServer

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def get_all(table_name \\ @table_name) do
    table_name
    |> :ets.match(:"$1")
    |> List.flatten()
  end

  def get_by_task_name(task_name, table_name \\ @table_name) do
    table_name
    |> :ets.match_object({task_name, :_, :_})
    |> List.flatten()
  end

  def get_by_hashed_identity(hashed_identity, table_name \\ @table_name) do
    table_name
    |> :ets.match_object({:_, hashed_identity, :_})
    |> List.flatten()
  end

  @spec register_submission(register_submission_opts()) :: :ok
  def register_submission(opts, pid \\ __MODULE__) do
    task = Keyword.fetch!(opts, :task)
    %Uptight.Base.Urlsafe{} = hashed_identity = Keyword.fetch!(opts, :hashed_identity)
    %Uptight.Text{} = submission_uuid = Keyword.fetch!(opts, :submission_uuid)

    GenServer.call(
      pid,
      {:register_submission, {ZhrDevs.Task.name(task), hashed_identity, submission_uuid}}
    )
  end

  def init(opts) do
    table_name = Keyword.get(opts, :table_name, @table_name)

    :ets.new(table_name, [:duplicate_bag, :named_table, :protected])

    {:ok, table_name}
  end

  def handle_call({:register_submission, {task_name, hid, submission_uuid}}, _from, table_name) do
    :ets.insert(table_name, {task_name, hid, submission_uuid})

    {:reply, :ok, table_name}
  end
end
