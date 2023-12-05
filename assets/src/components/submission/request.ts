import ApiError from "../../api_error"

export type TournamentResult = {
    hashed_id: string,
    is_baseline: boolean,
    norm: null,
    team: null,
    score: {
        points: number
    },
    me: boolean
}

export type SubmissionInfo = {
    counter: number,
    task: {
        uuid: string,
        name: string,
        technology: string,
    },
    results: TournamentResult[] | [],
    invitations: {
        invited: string[],
        interested: string[]
    }
}

export async function fetchSubmissionInfo(technology: string, task: string, host: string, port: string): Promise<SubmissionInfo | ApiError> {
    const opts = {
        headers: {
            "Content-Type": "application/json",
        }
    }

    const url = `/my/submission/nt/${task}/${technology}`

    return fetch(url, opts).then(response => response.json())
}
