import { Landmark, Bell, LogOut, User, Shield } from "lucide-react";
import { useAdminAuth } from "../context/AdminAuthContext";
import { useNavigate } from "react-router-dom";

export default function AdminHeader() {
  const { adminUser, logout } = useAdminAuth();
  const navigate = useNavigate();

  const handleLogoutClick = () => {
    logout();
    navigate("/login");
  };

  return (
    <header
      style={{
        height: "var(--header-height)",
        background: "rgba(17, 24, 39, 0.85)",
        backdropFilter: "blur(12px)",
        borderBottom: "1px solid var(--border-color)",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "0 28px",
        position: "sticky",
        top: 0,
        zIndex: 40
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "10px",
            background: "rgba(99, 102, 241, 0.1)",
            border: "1px solid rgba(99, 102, 241, 0.25)",
            padding: "6px 14px",
            borderRadius: "var(--radius-full)"
          }}
        >
          <Landmark size={18} style={{ color: "var(--primary)" }} />
          <span style={{ fontSize: "0.85rem", fontWeight: "700", color: "#f3f4f6" }}>
            National Education Analytics Portal
          </span>
          <span className="badge badge-cyan" style={{ fontSize: "0.7rem" }}>
            {adminUser?.organization || "Maharashtra State Council"}
          </span>
        </div>
      </div>

      <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
        <button
          className="btn btn-outline btn-icon"
          title="Notifications"
          style={{ position: "relative" }}
        >
          <Bell size={18} />
          <span
            style={{
              position: "absolute",
              top: "6px",
              right: "6px",
              width: "8px",
              height: "8px",
              borderRadius: "50%",
              background: "var(--accent-rose)"
            }}
          />
        </button>

        <div style={{ width: "1px", height: "24px", background: "var(--border-color)" }} />

        {/* User Pill */}
        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
          <div
            style={{
              width: "36px",
              height: "36px",
              borderRadius: "50%",
              background: "linear-gradient(135deg, var(--primary) 0%, #3b82f6 100%)",
              color: "#fff",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontWeight: "700",
              fontSize: "0.85rem"
            }}
          >
            {adminUser?.avatar || "AD"}
          </div>

          <div style={{ display: "flex", flexDirection: "column" }}>
            <span style={{ fontSize: "0.85rem", fontWeight: "600", color: "var(--text-main)", lineHeight: 1.2 }}>
              {adminUser?.name || "Admin User"}
            </span>
            <span style={{ fontSize: "0.72rem", color: "var(--text-muted)" }}>
              {adminUser?.role || "Super Admin"}
            </span>
          </div>
        </div>

        <button
          className="btn btn-outline btn-sm"
          onClick={handleLogoutClick}
          style={{ color: "var(--accent-rose)", borderColor: "rgba(244, 63, 94, 0.3)", marginLeft: "8px" }}
          title="Sign Out of Admin Portal"
        >
          <LogOut size={14} />
          <span>Logout</span>
        </button>
      </div>
    </header>
  );
}
