function Invites(props: {invited: string[], interested: string[], testCompleted: boolean}) {

  let application: JSX.Element

  if (props.testCompleted) {
    application = <button type="submit" className="rounded bg-purple-300 text-white">Apply</button>
  } else {
    application = <p className="text-slate-400">You will be able to apply when completing the test</p>
  }

  return (
    <div className="px-8 py-4 bg-slate-200 rounded leading-loose">
      <p className="font-semibold">You were invited by</p>
      {props.invited.map(invitedBy => {
        return <p>{invitedBy}</p>
      })}

      <p className="mt-4 font-semibold">Other companies interested</p>
      {props.interested.map(interested => {
        return <p>{interested}</p>
      })}

      <div className="text-center">
        {application}
      </div>
    </div>
  );
}

export default Invites;
