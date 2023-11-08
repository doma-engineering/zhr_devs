import React, { FC } from "react";
import { TournamentResult } from "./request";

export type { TournamentResult } from "./request";

const TournamentTable: FC<{ result: [TournamentResult] }> = ({
  result
}) => {
  return (
    // TailwindCSS table
    <table className="table-auto w-full">
      <thead>
        <tr>
          <th className="px-4 py-2 text-purple-400">User</th>
          <th className="px-4 py-2 text-purple-400">Score</th>
          <th className="px-4 py-2 text-purple-400">Baseline</th>
        </tr>
      </thead>
      <tbody>
        {result.map(entry => (
          <tr key={entry.hashed_id} className={entry.my ? "bg-purple-400" : ""}>
            <td className="border px-4 py-2">{entry.hashed_id}</td>
            <td className="border px-4 py-2">{entry.score.points}</td>
            <td className="border px-4 py-2">{entry.is_baseline ? "Yes" : "No"}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}

export default TournamentTable