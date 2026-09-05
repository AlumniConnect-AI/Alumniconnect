import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Shield, Lock, Mail, ArrowRight, CheckCircle2 } from "lucide-react";
import { useAdminAuth } from "../context/AdminAuthContext";

export default function Login() {
  const [email, setEmail] = useState("admin@maharashtra.edu.gov.in");
  const [password, setPassword] = useState("admin123");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const { login } = useAdminAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    if (!email || !password) {
      setError("Please fill in both Email and Password fields.");
      return;
    }
    try {
      setLoading(true);
      await login(email, password);
      navigate("/dashboard");
    } catch (err) {
      setError(err.message || "Failed to authenticate admin.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "radial-gradient(circle at top right, #1f293d 0%, #0b0f19 60%)",
        padding: "24px"
      }}
    >
      <div
        className="glass-card animate-fade-in"
        style={{ width: "100%", maxWidth: "440px", padding: "36px" }}
      >
        <div style={{ textAlign: "center", marginBottom: "28px" }}>
          <div
            style={{
              width: "56px",
              height: "56px",
              borderRadius: "16px",
              background: "linear-gradient(135deg, var(--primary) 0%, #06b6d4 100%)",
              color: "#fff",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              margin: "0 auto 16px",
              boxShadow: "0 0 24px rgba(99, 102, 241, 0.4)"
            }}
          >
            <Shield size={30} />
          </div>

          <h1 style={{ fontSize: "1.75rem", fontWeight: "800", color: "#f9fafb" }}>
            Admin Portal
          </h1>
          <p style={{ fontSize: "0.9rem", color: "var(--text-muted)", marginTop: "4px" }}>
            National Education & Career Analytics
          </p>
          <span className="badge badge-indigo" style={{ marginTop: "10px" }}>
            Maharashtra State & All-India Council Access
          </span>
        </div>

        {error && (
          <div
            style={{
              background: "rgba(244, 63, 94, 0.15)",
              border: "1px solid rgba(244, 63, 94, 0.3)",
              color: "#f87171",
              padding: "12px",
              borderRadius: "var(--radius-md)",
              fontSize: "0.85rem",
              marginBottom: "20px"
            }}
          >
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Admin Official Email</label>
            <div style={{ position: "relative" }}>
              <Mail
                size={18}
                style={{
                  position: "absolute",
                  left: "14px",
                  top: "50%",
                  transform: "translateY(-50%)",
                  color: "var(--text-muted)"
                }}
              />
              <input
                type="email"
                className="form-control"
                placeholder="admin@council.edu.gov.in"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={{ paddingLeft: "42px" }}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <label>Password</label>
              <a href="#" onClick={(e) => { e.preventDefault(); alert("Password reset link sent to official email."); }} style={{ fontSize: "0.8rem" }}>
                Forgot Password?
              </a>
            </div>
            <div style={{ position: "relative" }}>
              <Lock
                size={18}
                style={{
                  position: "absolute",
                  left: "14px",
                  top: "50%",
                  transform: "translateY(-50%)",
                  color: "var(--text-muted)"
                }}
              />
              <input
                type="password"
                className="form-control"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={{ paddingLeft: "42px" }}
                required
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: "100%", marginTop: "12px", padding: "12px" }}
            disabled={loading}
          >
            {loading ? "Authenticating Admin..." : "Sign In to Admin Portal"}
            {!loading && <ArrowRight size={18} />}
          </button>
        </form>

        <div style={{ marginTop: "24px", paddingTop: "20px", borderTop: "1px solid var(--border-color)", textAlign: "center", fontSize: "0.88rem" }}>
          <span style={{ color: "var(--text-muted)" }}>Don't have an admin account? </span>
          <Link to="/signup" style={{ fontWeight: "600" }}>
            Create Admin Account
          </Link>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "8px", justifyContent: "center", marginTop: "20px", fontSize: "0.75rem", color: "var(--text-dim)" }}>
          <CheckCircle2 size={14} style={{ color: "var(--accent-emerald)" }} />
          <span>Demo Representation of Ministry/Council Level System</span>
        </div>
      </div>
    </div>
  );
}
