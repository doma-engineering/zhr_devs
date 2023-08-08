import ApiError from "../../api_error"

type Task = {
    technology: string,
    counter: number
}

type Tasks = {
    tasks: [Task]
}

export default async function fetchTasks(host: string, port: string): Promise<Tasks | ApiError> {
    const opts = {
        headers: {
            "Content-Type": "application/json",
        }
    }

    const url = `${window.location.protocol}//${host}:${port}/my/tasks`

    return fetch(url, opts).then(response => response.json())
}
