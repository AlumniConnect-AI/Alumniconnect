import { useState, useEffect } from "react";
import { X, Building2, Save } from "lucide-react";
import { STATES_LIST } from "../data/adminMockData";

export default function UniversityFormModal({ isOpen, onClose, onSave, initialData }) {
  const [formData, setFormData] = useState({
    name: "",
    type: "State Public",
    state: "Maharashtra",
    district: "Mumbai City",
    city: "Mumbai",
    address: "",
    website: "",
    estYear: "2000",
    institutions: 50,
    students: 25000,
    courses: 120,
    graduationRate: 78.5,
    placementRate: 72.0,
    status: "Active"
  });
  const [error, setError] = useState("");

  useEffect(() => {
    if (initialData) {
      setFormData({
        ...initialData,
        city: initialData.district || "Mumbai"
      });
    } else {
      setFormData({
        name: "",
        type: "State Public",
        state: "Maharashtra",
        district: "Mumbai City",
        city: "Mumbai",
        address: "",
        website: "",
        estYear: "2000",
        institutions: 50,
        students: 25000,
        courses: 120,
        graduationRate: 78.5,
        placementRate: 72.0,
        status: "Active"
      });
    }
  }, [initialData, isOpen]);

  if (!isOpen) return null;

  const handleChange = (field, val) => {
    setFormData(prev => ({ ...prev, [field]: val }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setError("");

    if (!formData.name || !formData.state || !formData.district) {
      setError("University Name, State, and District are required.");
      return;
    }

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
      <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "620px", background: "#111827", maxHeight: "90vh", overflowY: "auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <Building2 size={24} style={{ color: "var(--primary)" }} />
            <h3 style={{ fontSize: "1.25rem", fontWeight: "700" }}>
              {initialData ? "Edit University Record" : "Add New University"}
            </h3>
          </div>
          <button className="btn btn-outline btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        {error && (
          <div style={{ background: "rgba(244, 63, 94, 0.15)", border: "1px solid rgba(244, 63, 94, 0.3)", color: "#f87171", padding: "10px 14px", borderRadius: "var(--radius-md)", fontSize: "0.85rem", marginBottom: "16px" }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>University Name *</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Maharashtra University of Health Sciences"
              value={formData.name}
              onChange={(e) => handleChange("name", e.target.value)}
              required
            />
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>University Type *</label>
              <select
                className="form-select"
                value={formData.type}
                onChange={(e) => handleChange("type", e.target.value)}
              >
                <option value="State Public">State Public</option>
                <option value="State Technical">State Technical</option>
                <option value="Central Public">Central Public</option>
                <option value="Deemed University">Deemed University</option>
                <option value="Private Autonomous">Private Autonomous</option>
              </select>
            </div>

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
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>District *</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Pune / Mumbai City"
                value={formData.district}
                onChange={(e) => handleChange("district", e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label>Established Year</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. 1998"
                value={formData.estYear}
                onChange={(e) => handleChange("estYear", e.target.value)}
              />
            </div>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Website URL</label>
              <input
                type="url"
                className="form-control"
                placeholder="https://univ.ac.in"
                value={formData.website}
                onChange={(e) => handleChange("website", e.target.value)}
              />
            </div>

            <div className="form-group">
              <label>Status</label>
              <select
                className="form-select"
                value={formData.status}
                onChange={(e) => handleChange("status", e.target.value)}
              >
                <option value="Active">Active</option>
                <option value="Verified">Verified</option>
                <option value="Pending">Pending Audit</option>
              </select>
            </div>
          </div>

          <div className="grid-3">
            <div className="form-group">
              <label>Affiliated Colleges</label>
              <input
                type="number"
                className="form-control"
                value={formData.institutions}
                onChange={(e) => handleChange("institutions", e.target.value)}
              />
            </div>

            <div className="form-group">
              <label>Total Enrolled Students</label>
              <input
                type="number"
                className="form-control"
                value={formData.students}
                onChange={(e) => handleChange("students", e.target.value)}
              />
            </div>

            <div className="form-group">
              <label>Placement Rate (%)</label>
              <input
                type="number"
                step="0.1"
                className="form-control"
                value={formData.placementRate}
                onChange={(e) => handleChange("placementRate", e.target.value)}
              />
            </div>
          </div>

          <div style={{ marginTop: "24px", display: "flex", justifyContent: "flex-end", gap: "10px" }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              <Save size={16} /> {initialData ? "Save Changes" : "Create University"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
