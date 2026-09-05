import React from "react";
import { X, User, Mail, Building, GraduationCap, Briefcase, MapPin, Linkedin, Clock, Calendar, CheckCircle, XCircle } from "lucide-react";
import StatusBadge from "./StatusBadge";

export default function UserProfileModal({ isOpen, onClose, user }) {
  if (!isOpen || !user) return null;

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: "rgba(15, 23, 42, 0.75)",
        backdropFilter: "blur(6px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1000,
        padding: "20px"
      }}
      onClick={onClose}
    >
      <div
        className="glass-card animate-fade-in"
        style={{
          width: "100%",
          maxWidth: "600px",
          maxHeight: "90vh",
          overflowY: "auto",
          background: "#0f172a",
          border: "1px solid var(--border-color)",
          borderRadius: "16px",
          boxShadow: "0 20px 40px rgba(0,0,0,0.5)",
          padding: "28px",
          position: "relative"
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          style={{
            position: "absolute",
            top: "20px",
            right: "20px",
            background: "rgba(255,255,255,0.05)",
            border: "1px solid var(--border-color)",
            borderRadius: "50%",
            width: "36px",
            height: "36px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "var(--text-muted)",
            cursor: "pointer"
          }}
        >
          <X size={18} />
        </button>

        {/* Header Avatar & Basic Info */}
        <div style={{ display: "flex", alignItems: "center", gap: "16px", marginBottom: "24px", borderBottom: "1px solid var(--border-color)", paddingBottom: "20px" }}>
          {user.photoURL ? (
            <img
              src={user.photoURL}
              alt={user.name}
              style={{ width: "64px", height: "64px", borderRadius: "50%", objectFit: "cover", border: "2px solid var(--primary)" }}
            />
          ) : (
            <div
              style={{
                width: "64px",
                height: "64px",
                borderRadius: "50%",
                background: "linear-gradient(135deg, var(--primary) 0%, #38bdf8 100%)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "#fff",
                fontSize: "1.5rem",
                fontWeight: "700",
                boxShadow: "0 0 16px rgba(99, 102, 241, 0.3)"
              }}
            >
              {user.name ? user.name.charAt(0).toUpperCase() : "U"}
            </div>
          )}
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
              <h2 style={{ fontSize: "1.35rem", fontWeight: "700", color: "#f9fafb" }}>{user.name}</h2>
              <StatusBadge status={user.category} />
            </div>
            <p style={{ fontSize: "0.88rem", color: "var(--text-muted)", marginTop: "2px" }}>{user.email}</p>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", marginTop: "6px", fontSize: "0.78rem" }}>
              {user.online ? (
                <span style={{ color: "var(--accent-emerald)", display: "flex", alignItems: "center", gap: "4px", fontWeight: "600" }}>
                  <CheckCircle size={14} /> Currently Online
                </span>
              ) : (
                <span style={{ color: "var(--text-dim)", display: "flex", alignItems: "center", gap: "4px" }}>
                  <XCircle size={14} /> Offline (Last Seen: {user.lastSeen})
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Bio Section */}
        {user.bio && user.bio !== "No bio provided" && (
          <div style={{ marginBottom: "20px", background: "rgba(255,255,255,0.02)", padding: "14px", borderRadius: "10px", border: "1px solid rgba(255,255,255,0.05)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-dim)", textTransform: "uppercase", fontWeight: "700", marginBottom: "4px" }}>Bio / Profile Summary</div>
            <div style={{ fontSize: "0.88rem", color: "#e2e8f0", lineHeight: "1.4" }}>{user.bio}</div>
          </div>
        )}

        {/* User Details Grid */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
          <div className="glass-card" style={{ padding: "14px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "var(--accent-cyan)", fontSize: "0.8rem", fontWeight: "600", marginBottom: "4px" }}>
              <GraduationCap size={16} /> Department / Course
            </div>
            <div style={{ fontSize: "0.92rem", color: "#f9fafb", fontWeight: "600" }}>{user.department}</div>
          </div>

          <div className="glass-card" style={{ padding: "14px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "var(--accent-indigo)", fontSize: "0.8rem", fontWeight: "600", marginBottom: "4px" }}>
              <Calendar size={16} /> Batch / Graduation Year
            </div>
            <div style={{ fontSize: "0.92rem", color: "#f9fafb", fontWeight: "600" }}>{user.batch}</div>
          </div>

          <div className="glass-card" style={{ padding: "14px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "var(--accent-amber)", fontSize: "0.8rem", fontWeight: "600", marginBottom: "4px" }}>
              <Briefcase size={16} /> Designation / Role
            </div>
            <div style={{ fontSize: "0.92rem", color: "#f9fafb", fontWeight: "600" }}>{user.designation}</div>
          </div>

          <div className="glass-card" style={{ padding: "14px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "var(--accent-emerald)", fontSize: "0.8rem", fontWeight: "600", marginBottom: "4px" }}>
              <Building size={16} /> Organization / Company
            </div>
            <div style={{ fontSize: "0.92rem", color: "#f9fafb", fontWeight: "600" }}>{user.company}</div>
          </div>

          <div className="glass-card" style={{ padding: "14px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "var(--accent-rose)", fontSize: "0.8rem", fontWeight: "600", marginBottom: "4px" }}>
              <MapPin size={16} /> Location
            </div>
            <div style={{ fontSize: "0.92rem", color: "#f9fafb", fontWeight: "600" }}>{user.location}</div>
          </div>

          <div className="glass-card" style={{ padding: "14px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "#38bdf8", fontSize: "0.8rem", fontWeight: "600", marginBottom: "4px" }}>
              <Linkedin size={16} /> LinkedIn Profile
            </div>
            {user.linkedin ? (
              <a
                href={user.linkedin.startsWith("http") ? user.linkedin : `https://${user.linkedin}`}
                target="_blank"
                rel="noreferrer"
                style={{ fontSize: "0.88rem", color: "#38bdf8", textDecoration: "underline", wordBreak: "break-all" }}
              >
                View LinkedIn
              </a>
            ) : (
              <div style={{ fontSize: "0.88rem", color: "var(--text-muted)" }}>Not Linked</div>
            )}
          </div>
        </div>

        {/* Footer Audit Info */}
        <div style={{ marginTop: "24px", paddingTop: "16px", borderTop: "1px solid var(--border-color)", display: "flex", justifyContent: "space-between", fontSize: "0.75rem", color: "var(--text-dim)" }}>
          <div>Firestore Document ID: <code>{user.id}</code></div>
          <div>Joined / Created: {user.createdAt}</div>
        </div>
      </div>
    </div>
  );
}
