import { NavLink } from "react-router-dom";
import {
  LayoutDashboard,
  Building2,
  School,
  Users,
  GraduationCap,
  Briefcase,
  UserCheck,
  BookOpen,
  TrendingUp,
  MapPin,
  FileSpreadsheet,
  Database,
  ShieldCheck,
  Settings,
  Shield,
  UserCog
} from "lucide-react";

const NAV_ITEMS = [
  { path: "/dashboard", label: "Dashboard Overview", icon: LayoutDashboard },
  { header: "ADMINISTRATION → USER DATA" },
  { path: "/users-data", label: "All Users", icon: UserCog },
  { path: "/users-data/students", label: "Students", icon: GraduationCap },
  { path: "/users-data/alumni", label: "Alumni", icon: Briefcase },
  { path: "/users-data/staff", label: "Staff", icon: UserCheck },
  { header: "INSTITUTIONS & ANALYTICS" },
  { path: "/universities", label: "Universities", icon: Building2 },
  { path: "/institutions", label: "Institutions", icon: School },
  { path: "/students", label: "Local Student System", icon: Users },
  { path: "/courses", label: "Courses", icon: BookOpen },
  { path: "/placements", label: "Placements", icon: Briefcase },
  { path: "/career-outcomes", label: "Career Outcomes", icon: TrendingUp },
  { path: "/state-analytics", label: "State Analytics", icon: MapPin },
  { path: "/reports", label: "Reports", icon: FileSpreadsheet },
  { path: "/data-management", label: "Data Management", icon: Database },
  { path: "/admin-management", label: "Admin Management", icon: ShieldCheck },
  { path: "/settings", label: "Settings", icon: Settings }
];


export default function AdminSidebar() {
  return (
    <aside
      style={{
        width: "var(--sidebar-width)",
        minWidth: "var(--sidebar-width)",
        background: "#0c1322",
        borderRight: "1px solid var(--border-color)",
        display: "flex",
        flexDirection: "column",
        height: "100vh",
        position: "sticky",
        top: 0,
        zIndex: 50
      }}
    >
      {/* Brand Header */}
      <div
        style={{
          padding: "20px 24px",
          borderBottom: "1px solid var(--border-color)",
          display: "flex",
          alignItems: "center",
          gap: "12px"
        }}
      >
        <div
          style={{
            width: "38px",
            height: "38px",
            borderRadius: "10px",
            background: "linear-gradient(135deg, var(--primary) 0%, #38bdf8 100%)",
            color: "#fff",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            boxShadow: "0 0 16px rgba(99, 102, 241, 0.4)"
          }}
        >
          <Shield size={22} />
        </div>
        <div>
          <h2 style={{ fontSize: "1.05rem", fontWeight: "800", color: "#f9fafb", lineHeight: 1.1 }}>
            Admin Portal
          </h2>
          <span style={{ fontSize: "0.72rem", color: "var(--text-muted)", fontWeight: "500" }}>
            Education & Career Analytics
          </span>
        </div>
      </div>

      {/* Navigation */}
      <nav style={{ padding: "16px 12px", flex: 1, overflowY: "auto", display: "flex", flexDirection: "column", gap: "4px" }}>
        <div style={{ fontSize: "0.7rem", fontWeight: "700", color: "var(--text-dim)", padding: "4px 12px", textTransform: "uppercase", letterSpacing: "0.08em" }}>
          Administration Navigation
        </div>
        {NAV_ITEMS.map((item, idx) => {
          if (item.header) {
            return (
              <div
                key={`header-${idx}`}
                style={{
                  fontSize: "0.68rem",
                  fontWeight: "700",
                  color: "var(--accent-cyan)",
                  padding: "12px 12px 4px 12px",
                  textTransform: "uppercase",
                  letterSpacing: "0.08em"
                }}
              >
                {item.header}
              </div>
            );
          }
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `nav-link ${isActive ? "active" : ""}`
              }
              style={({ isActive }) => ({
                display: "flex",
                alignItems: "center",
                gap: "12px",
                padding: "10px 14px",
                borderRadius: "var(--radius-md)",
                fontSize: "0.88rem",
                fontWeight: isActive ? "600" : "500",
                color: isActive ? "#ffffff" : "var(--text-muted)",
                background: isActive ? "linear-gradient(90deg, rgba(99, 102, 241, 0.2) 0%, rgba(99, 102, 241, 0.05) 100%)" : "transparent",
                borderLeft: isActive ? "3px solid var(--primary)" : "3px solid transparent",
                transition: "all 0.15s ease",
                textDecoration: "none"
              })}
            >
              <Icon size={18} />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      {/* Footer info */}
      <div style={{ padding: "16px 20px", borderTop: "1px solid var(--border-color)", fontSize: "0.75rem", color: "var(--text-dim)" }}>
        <div>National Analytics Engine v2.4</div>
        <div style={{ color: "var(--accent-emerald)", marginTop: "2px" }}>● Live Council System</div>
      </div>
    </aside>
  );
}
