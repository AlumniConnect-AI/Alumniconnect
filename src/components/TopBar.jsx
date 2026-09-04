import { useLocation } from "react-router-dom";
import { Menu, Bell, Search } from "lucide-react";
import "./TopBar.css";

const pageTitles = {
    "/dashboard": "Dashboard",
    "/users": "User Management",
    "/jobs": "Job Moderation",
    "/events": "Event Management",
    "/analytics": "Analytics & Insights",
};

export default function TopBar({ collapsed, setCollapsed }) {
    const { pathname } = useLocation();
    const title = pageTitles[pathname] || "Dashboard";

    return (
        <header className="topbar">
            <div className="topbar-left">
                <button
                    className="topbar-menu-btn"
                    onClick={() => setCollapsed(!collapsed)}
                    aria-label="Toggle sidebar"
                >
                    <Menu size={20} />
                </button>
                <div>
                    <h1 className="topbar-title">{title}</h1>
                    <p className="topbar-subtitle">AlumniConnect Administration</p>
                </div>
            </div>

            <div className="topbar-right">
                <div className="topbar-search">
                    <Search size={16} className="topbar-search-icon" />
                    <input
                        type="text"
                        placeholder="Search..."
                        className="topbar-search-input"
                        id="global-search"
                    />
                </div>

                <button className="topbar-icon-btn" title="Notifications" id="notifications-btn">
                    <Bell size={19} />
                    <span className="topbar-notif-dot" />
                </button>

                <div className="topbar-avatar" title="Admin">
                    <span>A</span>
                </div>
            </div>
        </header>
    );
}
