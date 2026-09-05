import { useState, useEffect } from "react";
import { X, ShieldCheck, Save } from "lucide-react";
import { STATES_LIST } from "../data/adminMockData";

export default function AdminUserFormModal({ isOpen, onClose, onSave, initialData }) {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    organization: "",
    designation: "Analytics Administrator",
    role: "State Admin",
    state: "Maharashtra"
  });

  useEffect(() => {
    if (initialData) {
      setFormData({ ...initialData });
    } else {
      setFormData({
        name: "",
        email: "",
        organization: "",
        designation: "Analytics Administrator",
        role: "State Admin",
        state: "Maharashtra"
      });
    }
  }, [initialData, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name || !formData.email) return;
    onSave(formData);
    onClose();
  };

  return (
    <div
      style={{
        position: "fixed",
        top: 0, left: 0, right: 0, bottom: 0,
        background: "rgba(0,0,0,0.75)",
        backdropFilter: "blur(4px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 110,
        padding: "20px"
      }}
    >
      <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "540px", background: "#111827", maxHeight: "90vh", overflowY: "auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <ShieldCheck size={24} style={{ color: "var(--primary)" }} />
            <h3 style={{ fontSize: "1.25rem", fontWeight: "700" }}>
              {initialData ? "Edit Admin User" : "Add New Admin User"}
            </h3>
          </div>
          <button className="btn btn-outline btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Admin Full Name *</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Dr. Ramesh Chander"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label>Official Email Address *</label>
            <input
              type="email"
              className="form-control"
              placeholder="admin@edu.gov.in"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              required
            />
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Organization</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. State Education Board"
                value={formData.organization}
                onChange={(e) => setFormData({ ...formData, organization: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Designation</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Senior Director"
                value={formData.designation}
                onChange={(e) => setFormData({ ...formData, designation: e.target.value })}
              />
            </div>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Admin Governance Role</label>
              <select
                className="form-select"
                value={formData.role}
                onChange={(e) => setFormData({ ...formData, role: e.target.value })}
              >
                <option value="Super Admin">Super Admin</option>
                <option value="State Admin">State Admin</option>
                <option value="Data Administrator">Data Administrator</option>
                <option value="Analytics Administrator">Analytics Administrator</option>
                <option value="Institution Admin">Institution Admin</option>
              </select>
            </div>

            <div className="form-group">
              <label>Assigned Jurisdiction / State</label>
              <select
                className="form-select"
                value={formData.state}
                onChange={(e) => setFormData({ ...formData, state: e.target.value })}
              >
                {STATES_LIST.map(st => (
                  <option key={st} value={st}>{st}</option>
                ))}
              </select>
            </div>
          </div>

          <div style={{ marginTop: "24px", display: "flex", justifyContent: "flex-end", gap: "10px" }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              <Save size={16} /> {initialData ? "Save Changes" : "Create Admin User"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
