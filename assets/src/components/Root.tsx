import Navbar from './Navbar'
import { Outlet } from 'react-router-dom'
import { Routed } from '../router'

function Root(_props: Routed) {
    return (
        <div>
            <Navbar />

            <Outlet />
        </div>
    );
}

export default Root;
