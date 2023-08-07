import { RouterProvider } from 'react-router-dom';
import './App.css';

import { Router } from './router'

function App() {
    const router_concrete = Router({ host: 'localhost', port: '4001' });
    return <RouterProvider router={router_concrete} />
}

export default App;
