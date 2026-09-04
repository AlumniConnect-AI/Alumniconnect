import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import {
    LayoutDashboard,
    Users,
    Briefcase,
    CalendarDays,
    BarChart3,
    LogOut,
    GraduationCap,
    ChevronLeft,
    ChevronRight,
    ShieldCheck,
    AlertTriangle,
    ScrollText,
} from "lucide-react";
import "./Sidebar.css";

const navSections = [
    {
        label: "Main",
        items: [
            { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
        ],
    },
    {
        label: "Management",
        items: [
            { to: "/users", label: "User Management", icon: Users },
            { to: "/staff", label: "Staff Verification", icon: ShieldCheck },
        ],
    },
    {
        label: "Moderation",
        items: [
            { to: "/jobs", label: "Job Moderation", icon: Briefcase },
            { to: "/events", label: "Event Management", icon: CalendarDays },
            { to: "/reports", label: "Reports & Safety", icon: AlertTriangle },
        ],
    },
    {
        label: "System",
        items: [
            { to: "/analytics", label: "Analytics", icon: BarChart3 },
            { to: "/activity", label: "Activity Log", icon: ScrollText },
        ],
    },
];

export default function Sidebar({ collapsed, setCollapsed }) {
    const { logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = async () => {
        try { await logout(); } catch { }
        navigate("/");
    };

    return (
        <aside className={`sidebar ${collapsed ? "sidebar--collapsed" : ""}`}>
            {/* Brand */}
            <div className="sidebar-brand">
                <div className="sidebar-logo">
                    <GraduationCap size={24} strokeWidth={2.2} />
                </div>
                {!collapsed && (
                    <div className="sidebar-brand-text animate-fade-in">
                        <span className="sidebar-brand-name">AlumniConnect</span>
                        <span className="sidebar-brand-sub">Admin Panel</span>
                    </div>
                )}
            </div>

            {/* Navigation */}
            <nav className="sidebar-nav">
                {navSections.map((section) => (
                    <div className="sidebar-section" key={section.label}>
                        <div className="sidebar-section-label">
                            {!collapsed && section.label}
                        </div>
                        {section.items.map((item) => (
                            <NavLink
                                key={item.to}
                                to={item.to}
                                className={({ isActive }) =>
                                    `sidebar-link ${isActive ? "sidebar-link--active" : ""}`
                                }
                                title={item.label}
                            >
                                <item.icon size={20} strokeWidth={1.8} />
                                {!collapsed && <span>{item.label}</span>}
                                {!collapsed && <div className="sidebar-link-indicator" />}
                            </NavLink>
                        ))}
                    </div>
                ))}
            </nav>

            {/* Bottom actions */}
            <div className="sidebar-bottom">
                <button className="sidebar-link sidebar-logout" onClick={handleLogout} title="Sign Out">
                    <LogOut size={20} strokeWidth={1.8} />
                    {!collapsed && <span>Sign Out</span>}
                </button>

                <button
                    className="sidebar-collapse-btn"
                    onClick={() => setCollapsed(!collapsed)}
                    title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
                >
                    {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
                </button>
            </div>
        </aside>
    );
}
