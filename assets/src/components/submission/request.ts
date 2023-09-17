import ApiError from "../../api_error"

export type SubmissionInfo = {
    technology: string,
    counter: number,
    task: {
        id: string,
        name: string,
        technology: string,
        // description: string
    }
    invitations: {
        invited: string[],
        interested: string[]
    }
}

export async function fetchSubmissionInfo(technology: string, host: string, port: string): Promise<SubmissionInfo | ApiError> {
    const opts = {
        headers: {
            "Content-Type": "application/json",
        }
    }

    const url = `${window.location.protocol}//${host}:${port}/my/submission/${technology}`

    return fetch(url, opts).then(response => response.json())
}
