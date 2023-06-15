import { createBrowserRouter } from 'react-router-dom'

import Tasks from './components/Tasks'
import Submission from './components/Submission'

import Root from './components/Root'

const Router = createBrowserRouter([
  {
    path: "/my",
    element: <Root />,
    children: [
      {
        path: '', element: <Tasks />
      },
      {
        path: 'submissions/:tech', element: <Submission />
      }
    ]
  }
])

export default Router
