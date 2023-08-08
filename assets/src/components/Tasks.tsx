import { useState, useEffect } from "react";
import fetchTasks from './tasks/request'
import Task from './tasks/Task'
import { Routed } from '../router'

type State = [] | [{ technology: string, counter: number }]

function TasksIndex({ host, port }: Routed) {
    const [tasks, setTasks] = useState<State>([])

    useEffect(() => {
        fetchTasks(host, port).then(response => {
            if ('tasks' in response) {
                setTasks(response.tasks)
            } else {
                // Handle error
            }
        })
    }, tasks)

    return (
        <div className="flex mx-16 mt-48">
            <div className="flex-row basis-1/2 px-48">
                <h1 className="text-3xl font-bold">Tasks</h1>

                <p className="mt-6">
                    Some info about test flow, 2 attempts and any relevant info. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce nisl nibh, bibendum eu tincidunt eu, ultrices fermentum urna. Suspendisse accumsan ac nisl vel tincidunt. Aenean lorem ex, varius sed euismod non, luctus nec nisi. Aenean lorem ex, varius sed euismod non, luctus nec nisi. Mauris non mauris tristique enim vestibulum ornare quis vitae elit. Sed ligula dui, pretium non magna ac.
                </p>
            </div>

            <div className="flex basis-1/2 flex-wrap px-4 gap-8">
                {/* <Task technology={"elixir"} counter={0} renderLink={true} />
        <Task technology={"haskell"} counter={0} renderLink={true} />
        <Task technology={"rust"} counter={2} renderLink={true} />
        <Task technology={"typescript"} counter={2} renderLink={true} />
        <Task technology={"java"} counter={2} renderLink={true} />
        <Task technology={"kotlin"} counter={2} renderLink={true} /> */}

                {tasks.map(task =>
                    <Task technology={task.technology} counter={task.counter} renderLink={true} />
                )}
            </div>
        </div>
    );
}

export default TasksIndex
