import { createBrowserRouter } from 'react-router-dom'

import Tasks from './components/Tasks'
import Submission from './components/Submission'

import Root from './components/Root'

// Interface that accepts host and port of the backend
export interface Routed {
    host: string,
    port: string
}

// A react component that takes Routed props and returns a react Router with createBrowserRouter.
export const Router = ({ host, port }: Routed) => createBrowserRouter([
    {
        path: "/my",
        element: <Root host={host} port={port} />,
        children: [
            {
                path: '', element: <Tasks host={host} port={port} />
            },
            {
                path: 'submissions/nt/:task/:technology', element: <Submission host={host} port={port} />
            }
        ]
    }
])
