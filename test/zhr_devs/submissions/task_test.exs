# defmodule ZhrDevs.Submissions.TaskTest do
#   use ExUnit.Case, async: true

#   alias ZhrDevs.Submissions.Task
#   alias ZhrDevs.Submissions.Task.{Language, Library, Integration}

#   alias Uptight.Text, as: T
#   alias Uptight.Text.Urlencoded, as: TU

#   describe "new!/1" do
#     test "build new task struct without libraries and integrations" do
#       uri_encoded_string =
#         mk_url_encoded_string(%{
#           task_name: "onTheMap",
#           programming_language: "elixir",
#           libraries: [],
#           integrations: []
#         })

#       assert %Task{
#                task_name: %T{text: "onTheMap"},
#                programming_language: %Language{language: %T{text: "elixir"}},
#                libraries: [],
#                integrations: []
#              } == Task.new!(uri_encoded_string)
#     end

#     test "build new task struct with libraries and integrations" do
#       uri_encoded_string =
#         mk_url_encoded_string(%{
#           task_name: "onTheMap",
#           programming_language: "elixir",
#           libraries: ["uptight", "witchcraft"],
#           integrations: ["postgres"]
#         })

#       assert %Task{
#                task_name: %T{text: "onTheMap"},
#                programming_language: %Language{language: %T{text: "elixir"}},
#                libraries: [
#                  %Library{library: %T{text: "uptight"}},
#                  %Library{library: %T{text: "witchcraft"}}
#                ],
#                integrations: [%Integration{integration: %T{text: "postgres"}}]
#              } == Task.new!(uri_encoded_string)
#     end

#     test "preserves the ordering of the elements in list" do
#       left =
#         mk_url_encoded_string(%{
#           task_name: "onTheMap",
#           programming_language: "elixir",
#           libraries: ["uptight", "witchcraft"],
#           integrations: []
#         })

#       right =
#         mk_url_encoded_string(%{
#           task_name: "onTheMap",
#           programming_language: "elixir",
#           libraries: ["witchcraft", "uptight"],
#           integrations: []
#         })

#       refute Task.new!(left) === Task.new!(right)
#     end

#     test "raise if task_name is empty" do
#       uri_encoded_string =
#         mk_url_encoded_string(%{
#           task_name: "",
#           programming_language: "elixir",
#           libraries: ["uptight", "witchcraft"],
#           integrations: ["postgres"]
#         })

#       assert_raise(RuntimeError, fn ->
#         Task.new!(uri_encoded_string)
#       end)
#     end

#     test "raise if programming language is other then expected" do
#       for programming_language <- [nil, "javascript", "", " ", []] do
#         uri_encoded_string =
#           mk_url_encoded_string(%{
#             task_name: "onTheMap",
#             programming_language: programming_language,
#             libraries: [],
#             integrations: []
#           })

#         assert_raise(RuntimeError, fn ->
#           Task.new!(uri_encoded_string)
#         end)
#       end
#     end
#   end

#   describe "from_raw!/1" do
#     test "encodes a task correctly" do
#       task = %Task{
#         task_name: %T{text: "onTheMap"},
#         programming_language: %Language{language: %T{text: "elixir"}},
#         libraries: [
#           %Library{library: %T{text: "witchcraft"}},
#           %Library{library: %T{text: "uptight"}}
#         ],
#         integrations: [%Integration{integration: %T{text: "postgres"}}]
#       }

#       %TU{encoded: %T{text: encoded}} = Task.from_raw!(task)

#       assert task === Task.new!(encoded)
#     end
#   end

#   defp mk_url_encoded_string(map) do
#     map |> Jason.encode!() |> URI.encode_www_form()
#   end
# end
