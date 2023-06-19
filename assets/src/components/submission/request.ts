import ApiError from "../../api_error"

export type SubmissionInfo = {
  technology: string,
  counter: number,
  task: {
    id: string,
    description: string
  }
  invitations: {
    invited: string[],
    interested: string[]
  }
}

export async function fetchSubmissionInfo(technology: string): Promise<SubmissionInfo | ApiError> {
  const opts = {
    headers: {
      "Content-Type": "application/json",
    }
  }

  const url = `/my/submission/${technology}`

  return fetch(url, opts).then(response => response.json())
}
