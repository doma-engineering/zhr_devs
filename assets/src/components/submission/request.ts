import ApiError from "../../api_error"

export type AttemptScore = ScoreRow[]

export type ScoreRow = {
    division: string,
    failure: string | null,
    score: number
}

export type SubmissionInfo = {
    counter: number,
    task: {
        uuid: string,
        name: string,
        technology: string,
    }
    invitations: {
        invited: string[],
        interested: string[]
    },
    attempts: AttemptScore[] | []
}

export async function fetchSubmissionInfo(technology: string, task: string, host: string, port: string): Promise<SubmissionInfo | ApiError> {
    const opts = {
        headers: {
            "Content-Type": "application/json",
        }
    }

    const url = `${window.location.protocol}//${host}:${port}/my/submission/nt/${task}/${technology}`

    return fetch(url, opts).then(response => response.json())
}
