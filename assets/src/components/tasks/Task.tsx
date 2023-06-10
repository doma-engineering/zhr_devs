function Task(props: {technology: string, counter: number}) {
  let backgroundClass: string;

  if (props.counter === 2) {
    backgroundClass = "bg-purple-300"
  } else { backgroundClass = "bg-purple-600" }

  return (
    <div className={"text-white w-2/5 rounded p-4 " + backgroundClass}>
      <p className="text-xl capitalize">{props.technology}</p>
      
      <p className="mt-6">Attempts: {props.counter} / 2</p>
    </div>
  )
}

export default Task
