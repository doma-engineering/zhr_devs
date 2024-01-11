import ApiError from "../../api_error"

type Task = {
    technology: string,
    name: string,
    counter: number
}

type Tasks = {
    tasks: [Task]
}

type downloadType = "task" | "additionalInputs"

export async function fetchTasks(host: string, port: string): Promise<Tasks | ApiError> {
    const opts = {
        headers: {
            "Content-Type": "application/json",
        }
    }

    const url = 'my/tasks'

    return fetch(url, opts).then(response => response.json())
}

export function downloadTaskUrl(taskUUID: string, type: downloadType): string {
    return `/my/tasks/${taskUUID}/download?type=${type}`
}

export async function triggerManualCheck(taskUUID: string): Promise<object> {
    const headers = {
        "Content-Type": "application/json",
    }

    const url = '/my/task/trigger_manual_check'
    const body = JSON.stringify({taskUUID: taskUUID})

    return fetch(url, { method: "POST", body: body, headers: headers}).then((response) => response.json()).catch((error) => error.json());
}
