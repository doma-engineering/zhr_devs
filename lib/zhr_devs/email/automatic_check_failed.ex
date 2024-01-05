defmodule ZhrDevs.Email.AutomaticCheckFailed do
  @moduledoc """
  Builds an email that is sent to the submissions operator when an automatic check fails 3 times
  """

  alias ZhrDevs.BakeryIntegration.Commands.Command
  alias ZhrDevs.BakeryIntegration.Queue.RunningCheck

  @type text_html() :: {String.t(), String.t()}

  @spec build(RunningCheck.t(), Command.system_error()) :: text_html()
  def build(running_check, system_error) do
    text = build_text(running_check, system_error)
    html = build_html(running_check, system_error)

    {text, html}
  end

  def build_text(
        %RunningCheck{task_technology: task_technology, check_uuid: uuid},
        system_error
      ) do
    """
    Automatic check for #{task_technology} has failed 3 times.

    #{break_down_system_error(system_error, :text)}

    Triggered by solution with UUID: #{uuid}
    """
  end

  def build_html(
        %RunningCheck{task_technology: task_technology, check_uuid: uuid},
        system_error
      ) do
    """
    <h1>Automatic check for #{task_technology} has failed 3 times.</h1>

    <ul>
      #{break_down_system_error(system_error, :html)}
    </ul>

    <p>Triggered by solution with UUID: #{uuid}</p>
    """
  end

  defp break_down_system_error(system_error, :text) do
    Enum.map_join(system_error, "\n", fn {key, value} ->
      "#{capitalize(key)}: #{inspect(value)}"
    end)
  end

  defp break_down_system_error(system_error, :html) do
    Enum.map_join(system_error, "\n", fn {key, value} ->
      "<li>#{capitalize(key)}: #{inspect(value)}</li>"
    end)
  end

  defp capitalize(term) when is_atom(term) do
    Atom.to_string(term) |> String.capitalize()
  end

  defp capitalize(term) when is_binary(term) do
    String.capitalize(term)
  end
end
