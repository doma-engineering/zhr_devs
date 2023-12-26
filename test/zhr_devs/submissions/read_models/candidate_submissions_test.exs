defmodule ZhrDevs.Submissions.ReadModels.CandidateSubmissionsTest do
  use ExUnit.Case, async: true

  alias ZhrDevs.Submissions.ReadModels.CandidateSubmissions

  import ZhrDevs.Fixtures, only: [generate_hashed_identity: 0, build_task: 0]

  describe "get_all/0" do
    setup [:create_and_start_table]

    test "returns empty list when there are no submissions", %{table_name: table_name} do
      assert CandidateSubmissions.get_all(table_name) == []
    end

    test "return all existing entries as a flat list of tuples", %{
      table_name: table_name,
      owner: owner_pid
    } do
      {task, candidate_hashed_identity, submission_uuid} = generate_submission_tuple()
      task_name = ZhrDevs.Task.name(task)

      :ok =
        CandidateSubmissions.register_submission(
          [
            task: task,
            hashed_identity: candidate_hashed_identity,
            submission_uuid: submission_uuid
          ],
          owner_pid
        )

      assert [{^task_name, ^candidate_hashed_identity, ^submission_uuid}] =
               CandidateSubmissions.get_all(table_name)
    end

    test "allows multiple records with the same task as a key (duplicated bag)", %{
      table_name: table_name,
      owner: owner_pid
    } do
      {task, candidate_hashed_identity, submission_uuid_1} = generate_submission_tuple()
      {_, _, submission_uuid_2} = generate_submission_tuple()

      task_name = ZhrDevs.Task.name(task)

      :ok =
        CandidateSubmissions.register_submission(
          [
            task: task,
            hashed_identity: candidate_hashed_identity,
            submission_uuid: submission_uuid_1
          ],
          owner_pid
        )

      :ok =
        CandidateSubmissions.register_submission(
          [
            task: task,
            hashed_identity: candidate_hashed_identity,
            submission_uuid: submission_uuid_2
          ],
          owner_pid
        )

      submissions = CandidateSubmissions.get_all(table_name)

      assert Enum.count(submissions) == 2

      assert Enum.map(submissions, fn {_, _, submission_uuid} -> submission_uuid end)
             |> Enum.uniq()
             |> Enum.count() == 2

      assert Enum.all?(submissions, fn {tn, _, _} -> tn == task_name end)
    end
  end

  describe "get_by_task_name/1" do
    setup [:create_and_start_table]

    test "returns empty list when there are no submissions", %{table_name: table_name} do
      assert CandidateSubmissions.get_by_task_name(:non_existing_task, table_name) == []
    end

    test "returns all submissions for a given task", %{table_name: table_name, owner: owner_pid} do
      {task, candidate_hashed_identity, submission_uuid} = generate_submission_tuple()
      task_name = ZhrDevs.Task.name(task)

      :ok =
        CandidateSubmissions.register_submission(
          [
            task: task,
            hashed_identity: candidate_hashed_identity,
            submission_uuid: submission_uuid
          ],
          owner_pid
        )

      assert [{^task_name, ^candidate_hashed_identity, ^submission_uuid}] =
               CandidateSubmissions.get_by_task_name(task_name, table_name)

      assert [] == CandidateSubmissions.get_by_task_name(:non_existing_task, table_name)
    end
  end

  describe "get_by_hashed_identity/1" do
    setup [:create_and_start_table]

    test "returns empty list when there are no submissions", %{table_name: table_name} do
      {_, candidate_hashed_identity, _} = generate_submission_tuple()

      assert CandidateSubmissions.get_by_hashed_identity(candidate_hashed_identity, table_name) ==
               []
    end

    test "returns all submissions for a given task", %{table_name: table_name, owner: owner_pid} do
      {task, candidate_hashed_identity, submission_uuid} = generate_submission_tuple()
      task_name = ZhrDevs.Task.name(task)

      :ok =
        CandidateSubmissions.register_submission(
          [
            task: task,
            hashed_identity: candidate_hashed_identity,
            submission_uuid: submission_uuid
          ],
          owner_pid
        )

      assert [{^task_name, ^candidate_hashed_identity, ^submission_uuid}] =
               CandidateSubmissions.get_by_hashed_identity(candidate_hashed_identity, table_name)

      assert [] ==
               CandidateSubmissions.get_by_hashed_identity(generate_hashed_identity(), table_name)
    end
  end

  defp generate_submission_tuple(
         task \\ build_task(),
         hashed_identity \\ generate_hashed_identity()
       ) do
    submission_uuid = Commanded.UUID.uuid4() |> Uptight.Text.new!()

    {task, hashed_identity, submission_uuid}
  end

  defp create_and_start_table(_ctx) do
    table_name = random_table_name()

    table_owner_pid =
      start_supervised!({CandidateSubmissions, [table_name: table_name, name: table_name]})

    {:ok, table_name: table_name, owner: table_owner_pid}
  end

  defp random_table_name do
    :crypto.strong_rand_bytes(4) |> Base.encode64() |> binary_part(0, 4) |> String.to_atom()
  end
end
