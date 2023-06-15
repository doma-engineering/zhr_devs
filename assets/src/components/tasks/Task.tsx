import { Link } from 'react-router-dom'

function Task(props: {technology: string, counter: number, renderLink: boolean}) {
  let backgroundClass: string;
  let widthClass: string;

  const taskInfo = <>
    <p className="text-xl capitalize">{props.technology}</p>
      
    <p className="mt-6">Attempts: {props.counter} / 2</p>
  </>

  if (props.counter === 2) {
    backgroundClass = "bg-purple-300"
  } else { backgroundClass = "bg-purple-600" }

  if (props.renderLink) { widthClass = 'w-2/5' } else {
    widthClass = 'w-full'
  }

  let innerContent: JSX.Element

  if (props.counter < 2 && props.renderLink) {
    innerContent =
    <Link to={`submissions/${props.technology}`}>
      {taskInfo}
    </Link>
  } else {
    innerContent = taskInfo
  }

  return (    
    <div className={`text-white rounded ${widthClass} p-4 ${backgroundClass}`}>
      {innerContent}
    </div>
  )
}

export default Task
