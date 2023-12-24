import { useState, useEffect } from "react";
import { fetchSubmissionInfo } from './submission/request'
import { Link, useParams } from 'react-router-dom'
import { Routed } from '../router'

import { triggerManualCheck } from '../components/tasks/request'
import Task from '../components/tasks/Task'
import Invites from '../components/submission/Invites'
import UploadCompoment from "../components/submission/UploadComponent"
import TournamentTable from "./submission/TournamentTable";

import type { SubmissionInfo, TournamentResult } from "./submission/request";

type State = SubmissionInfo | undefined

// const DUMMY_SUBMISSION: SubmissionInfo = {
//     counter: 0,
//     task: {
//         uuid: 'taskID',
//         name: 'hanooy_maps',
//         technology: 'goo'
//     },
//     results:
//         [
//             {
//                 "hashed_id": "-HeoxYD4z_TXBdefTuKTpYxTX2VdHkC5R1WE2bxwfmA=",
//                 "is_baseline": false,
//                 "norm": null,
//                 "score": {
//                     "points": 0
//                 },
//                 "team": null,
//                 my: true,
//             },
//             {
//                 "hashed_id": "ltX89lzN_vh2DwbuEMqHcqac39joTwdXOypA_ktMFGg=",
//                 "is_baseline": true,
//                 "norm": null,
//                 "score": {
//                     "points": 48
//                 },
//                 "team": null,
//                 my: false
//             }
//         ],
//     invitations: {
//         invited: ['Geeks', 'Ancient Greeks'],
//         interested: ['Apple', 'Microsoft']
//     }
// }

function Submission({ host, port }: Routed) {
    const { technology, task } = useParams<{ technology?: string, task?: string }>()
    const [submissionInfo, setSubmissionInfo] = useState<State>(undefined)
    const [attempt, setAttempt] = useState<number>(0)

    function doFetchSubmissionInfo(tech: string, task: string) {
        fetchSubmissionInfo(tech, task, host, port).then(response => {
            if ('task' in response) {
                setSubmissionInfo(response)
                
                const attempts = response.counter < 2 ? response.counter + 1 : 2
                setAttempt(attempts)
            } else {
                console.dir(response)
                // return redirect("/my")
            }
        })
    }

    function doTriggerManualCheck(taskId: string) {
        triggerManualCheck(taskId).then(response => {
            if ('error' in response) {
                alert(response.error)
            } else {
                alert('Manual check triggered')
            }
        })
    }

    useEffect(() => {
        if (technology && task) {
            doFetchSubmissionInfo(technology, task)
            // setSubmissionInfo(DUMMY_SUBMISSION)

            // setAttempt(DUMMY_SUBMISSION.counter + 1)
        }
    }, [technology, task])

    return (
        <div className="mx-16 mt-12">
            <Link to="/my" className='text-gray text-sm'>Back to all tasks</Link>
            <div className="flex mt-4">
                <div className="flex-row basis-2/6">
                    {submissionInfo ?
                        <Task
                            technology={submissionInfo?.task.technology}
                            name={submissionInfo?.task.name}
                            counter={submissionInfo?.counter}
                            renderLink={false} /> :
                        <></>}

                    <div className="mt-4">
                        {submissionInfo ?
                            <Invites
                                invited={submissionInfo.invitations.invited}
                                interested={submissionInfo.invitations.interested}
                                testCompleted={submissionInfo.counter > 0} /> : <></>}
                    </div>

                    <div className="mt-4">
                        {submissionInfo ? <button className=" w-full rounded bg-purple-600 text-white p-2" onClick={() => doTriggerManualCheck(submissionInfo?.task.uuid)}>Trigger manual check</button> : <></>}
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
                            <button className="rounded bg-purple-400 text-white p-2 mt-4">Download task</button>
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
                                {submissionInfo && technology && task ? <UploadCompoment task={task} tech={technology} taskId={submissionInfo.task.uuid} /> : <></>}
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

                            {
                                submissionInfo ? <TournamentTable result={submissionInfo.results as [TournamentResult]} />
                                : <div className="text-center"><p className="text-purple-400 mt-4 text-lg">Results will be shown here</p></div>
                            }
                        </div>
                    </div>
                </section>

            </div>
        </div>
    );
}

export default Submission
