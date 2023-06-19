import { useState, useEffect } from "react";
import { fetchSubmissionInfo } from './submission/request'
import { Link, useParams } from 'react-router-dom'

import Task from '../components/tasks/Task'
import Invites from '../components/submission/Invites'
import DragAndDrop from "./submission/DragAndDrop";

import type { SubmissionInfo } from "./submission/request";

import { redirect } from "react-router-dom";

type State = SubmissionInfo | undefined

// const DUMMY_SUBMISSION: SubmissionInfo = {
//   technology: 'elixir',
//   counter: 0,
//   task: {
//     id: 'taskID',
//     description: 'In this task you are working with a fictional startup’s marketing department to come up with an optimal automated bidding strategy to get the most out of an ad slot on a popular website'
//   },
//   invitations: {
//     invited: ['Geeks', 'Ancient Greeks'],
//     interested: ['Apple', 'Microsoft']
//   }
// }

function Submission() {
  const { tech } = useParams<{tech?: string}>()
  const [submissionInfo, setSubmissionInfo] = useState<State>(undefined)
  const [attempt, setAttempt] = useState<number>(0)
  const [downloadTaskUrl, setDownloadTaskUrl] = useState<string>('')

  function doFetchSubmissionInfo (tech: string) {
    fetchSubmissionInfo(tech).then(response => {
      if ('technology' in response) {
        setSubmissionInfo(response)
        setDownloadTaskUrl(`/my/task/${response.task.id}/download`)
        setAttempt(response.counter + 1)
      } else {
        return redirect("/my")
      }
    })
  }

  function handleDownloadTask() {
    return redirect(downloadTaskUrl)
  }

  useEffect(() => {
    if (tech) {
      doFetchSubmissionInfo(tech)
      // setSubmissionInfo(DUMMY_SUBMISSION)

      // setAttempt(DUMMY_SUBMISSION.counter + 1)
    }
  }, [tech])

  return (
    <div className="mx-16 mt-12">
      <Link to="/my" className='text-gray text-sm'>Back to all tasks</Link>
      <div className="flex mt-4">
        <div className="flex-row basis-2/6">
          {submissionInfo ? <Task technology={submissionInfo?.technology} counter={submissionInfo?.counter} renderLink={false} /> : <></>}

          <p className="mt-4">
            {submissionInfo ? submissionInfo.task.description : <></>}
          </p>

          <div className="mt-4">
            {submissionInfo ?
              <Invites
                invited={submissionInfo.invitations.invited}
                interested={submissionInfo.invitations.interested}
                testCompleted={submissionInfo.counter > 0} /> : <></>}
          </div>
        </div>

        <section className="ml-8 w-full">
          <div className="flex">
            <div className="flex rounded-full bg-purple-400 text-md text-white w-8 h-8 items-center justify-center p-4">
              <span>1</span>
            </div>
            <div className="ml-4">
              <span className="text-lg font-bold">Get the Task</span>
              <p className="mt-4 text-sm">Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque at felis lobortis, pulvinar justo mattis, tincidunt erat. Sed odio enim, dictum id imperdiet eget</p>
              <Link to={downloadTaskUrl} className="rounded bg-purple-400 text-white p-2 mt-4 inline-block" target="_blank">Download task</Link>
            </div>
          </div>

          <div className="flex mt-4">
            <div className="flex rounded-full bg-purple-400 text-md text-white w-8 h-8 items-center justify-center p-4">
              <span>2</span>
            </div>
            <div className="ml-4">
              <span className="text-lg font-bold">Submit your result / Attempt {attempt}</span>
              <p className="mt-4 text-sm">Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque at felis lobortis, pulvinar justo mattis, tincidunt erat. Sed odio enim, dictum id imperdiet eget</p>

              <div className="max-w-full mt-4">
                <DragAndDrop />
              </div>

              <button className="rounded bg-purple-400 text-white p-2 mt-4">Submit</button>
            </div>
          </div>

          <div className="flex mt-4">
            <div className="flex rounded-full bg-none text-none w-8 h-8 items-center justify-center">
              <span></span>
            </div>
            <div className="ml-4 w-full">
              <div className="border-b-slate-200 border-b">
                <span className="text-lg text-purple-400">Attempt {attempt}</span>
              </div>
              <div className="text-center">
                <p className="text-purple-400 mt-4 text-lg">Results will be shown here</p>
              </div>
            </div>
          </div>
        </section>

      </div>
    </div>
  );
}

export default Submission
