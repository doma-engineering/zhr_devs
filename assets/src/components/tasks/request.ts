import ApiError from "../../api_error"

type Task = {
  technology: string,
  counter: number
}

type Tasks = {
  tasks: [Task]
}

export default async function fetchTasks(): Promise<Tasks | ApiError> {
  const opts = {
    headers: {
      "Content-Type": "application/json",
    }
  }

  return fetch('/my/tasks/', opts).then(response => response.json())
}
