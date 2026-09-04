import { useState } from "react";
import { Outlet } from "react-router-dom";
import Sidebar from "./Sidebar";
import TopBar from "./TopBar";
import "./Layout.css";

export default function Layout() {
    const [collapsed, setCollapsed] = useState(false);

    return (
        <div className={`layout ${collapsed ? "layout--collapsed" : ""}`}>
            <Sidebar collapsed={collapsed} setCollapsed={setCollapsed} />
            <div className="layout-main">
                <TopBar collapsed={collapsed} setCollapsed={setCollapsed} />
                <main className="layout-content">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}
