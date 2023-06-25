defmodule ZhrDevs.Submissions.Task do
  @moduledoc """
  Data structure that represents a task that candidates is supposed to solve.
  """

  @dialyzer {:nowarn_function, [new: 0, new: 1, new: 2, new: 3]}

  import Algae

  defmodule Language do
    @moduledoc "The supported language in which task is written"
    defdata(Uptight.Text.t())
  end

  defmodule Library do
    @moduledoc "The libraries used in task"
    defdata(Uptight.Text.t())
  end

  defmodule Integration do
    @moduledoc false
    defdata(Uptight.Text.t())
  end

  defdata do
    task_name :: Uptight.Text.t()
    programming_language :: Language.t()
    integrations :: Integration.t() \\ nil
    library_stack :: Library.t() \\ nil
  end
end
