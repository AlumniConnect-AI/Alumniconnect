import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Shield, User, Mail, Lock, Building, MapPin, ArrowRight, ArrowLeft } from "lucide-react";
import { useAdminAuth } from "../context/AdminAuthContext";
import { STATES_LIST } from "../data/adminMockData";

export default function Signup() {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
    organization: "Maharashtra State Council",
    designation: "Data Coordinator",
    state: "Maharashtra",
    role: "State Admin"
  });

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const { signup } = useAdminAuth();
  const navigate = useNavigate();

  const handleChange = (field, val) => {
    setFormData(prev => ({ ...prev, [field]: val }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    if (!formData.name || !formData.email || !formData.password) {
      setError("Please complete all required fields.");
      return;
    }
    if (formData.password !== formData.confirmPassword) {
      setError("Passwords do not match. Please verify.");
      return;
    }

    try {
      setLoading(true);
      await signup(formData);
      navigate("/dashboard");
    } catch (err) {
      setError(err.message || "Admin registration failed.");
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
        background: "radial-gradient(circle at top left, #1f293d 0%, #0b0f19 60%)",
        padding: "32px 24px"
      }}
    >
      <div
        className="glass-card animate-fade-in"
        style={{ width: "100%", maxWidth: "600px", padding: "36px" }}
      >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "24px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <div
              style={{
                width: "44px",
                height: "44px",
                borderRadius: "12px",
                background: "linear-gradient(135deg, var(--primary) 0%, #06b6d4 100%)",
                color: "#fff",
                display: "flex",
                alignItems: "center",
                justifyContent: "center"
              }}
            >
              <Shield size={24} />
            </div>
            <div>
              <h1 style={{ fontSize: "1.4rem", fontWeight: "800", color: "#f9fafb" }}>
                Create Admin Account
              </h1>
              <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
                National Education & Career Analytics Portal
              </p>
            </div>
          </div>

          <Link to="/login" className="btn btn-outline btn-sm" style={{ gap: "6px" }}>
            <ArrowLeft size={14} /> Back to Login
          </Link>
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
          <div className="grid-2">
            <div className="form-group">
              <label>Full Name *</label>
              <input
                type="text"
                className="form-control"
                placeholder="Dr. Ananya Roy"
                value={formData.name}
                onChange={(e) => handleChange("name", e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label>Official Email *</label>
              <input
                type="email"
                className="form-control"
                placeholder="ananya@state.edu.gov.in"
                value={formData.email}
                onChange={(e) => handleChange("email", e.target.value)}
                required
              />
            </div>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Organization / Council *</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Maharashtra State Council"
                value={formData.organization}
                onChange={(e) => handleChange("organization", e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label>Designation *</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Senior Data Analyst"
                value={formData.designation}
                onChange={(e) => handleChange("designation", e.target.value)}
                required
              />
            </div>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Administrative State *</label>
              <select
                className="form-select"
                value={formData.state}
                onChange={(e) => handleChange("state", e.target.value)}
              >
                {STATES_LIST.filter(s => s !== "All India").map(st => (
                  <option key={st} value={st}>{st}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>Admin Role *</label>
              <select
                className="form-select"
                value={formData.role}
                onChange={(e) => handleChange("role", e.target.value)}
              >
                <option value="Super Admin">Super Admin</option>
                <option value="State Admin">State Admin</option>
                <option value="Data Administrator">Data Administrator</option>
                <option value="Analytics Administrator">Analytics Administrator</option>
                <option value="Institution Administrator">Institution Administrator</option>
              </select>
            </div>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Password *</label>
              <input
                type="password"
                className="form-control"
                placeholder="••••••••"
                value={formData.password}
                onChange={(e) => handleChange("password", e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label>Confirm Password *</label>
              <input
                type="password"
                className="form-control"
                placeholder="••••••••"
                value={formData.confirmPassword}
                onChange={(e) => handleChange("confirmPassword", e.target.value)}
                required
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: "100%", marginTop: "16px", padding: "12px" }}
            disabled={loading}
          >
            {loading ? "Registering Admin..." : "Complete Registration"}
            {!loading && <ArrowRight size={18} />}
          </button>
        </form>

        <div style={{ marginTop: "20px", textAlign: "center", fontSize: "0.85rem", color: "var(--text-muted)" }}>
          Already registered? <Link to="/login" style={{ fontWeight: "600" }}>Sign In</Link>
        </div>
      </div>
    </div>
  );
}
