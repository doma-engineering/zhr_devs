import { FC } from "react";
import type { AttemptScore } from "./request";

const ScoreTable: FC<{ rows: AttemptScore }> = ({ rows }) => {
    return (
      <table className="table-auto w-full mt-4 text-center">
        <thead>
          <tr>
            <th>Division</th>
            <th>Failure</th>
            <th>Score</th>
          </tr>
        </thead>

        <tbody>
          {rows.map((row, index) => (
            <tr key={index}>
              <td>{row.division}</td>
              <td>{row.failure}</td>
              <td>{row.score}</td>
            </tr>
          ))}
        </tbody>
      </table>
    );
};

export default ScoreTable;
