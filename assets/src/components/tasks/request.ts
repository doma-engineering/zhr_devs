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

export function downloadTask(taskUUID: string, type: downloadType): void {
    const url = `my/tasks/${taskUUID}/download?type=${type}`
    const filename = `${type}.zip`

    fetch(url, { method: "get", mode: "no-cors", referrerPolicy: "no-referrer" })
    .then((res) => res.blob())
    .then((res) => {
      const aElement = document.createElement("a");
      aElement.setAttribute("download", filename);
      const href = URL.createObjectURL(res);
      aElement.href = href;
      aElement.setAttribute("target", "_blank");
      aElement.click();
      URL.revokeObjectURL(href);
    });
}

export async function triggerManualCheck(taskUUID: string): Promise<object> {
    const headers = {
        "Content-Type": "application/json",
    }

    const url = '/my/task/trigger_manual_check'
    const body = JSON.stringify({taskUUID: taskUUID})

    return fetch(url, { method: "POST", body: body, headers: headers}).then((response) => response.json()).catch((error) => error.json());
}
