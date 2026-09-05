import { useState, useEffect } from "react";
import { X, GraduationCap, Save } from "lucide-react";
import { STATES_LIST } from "../data/adminMockData";

export default function InstitutionFormModal({ isOpen, onClose, onSave, initialData, universities }) {
  const [formData, setFormData] = useState({
    name: "",
    university: "",
    state: "Maharashtra",
    district: "Pune",
    courses: 20,
    students: 2500,
    graduates: 600,
    placementRate: 85.0,
    internshipRate: 90.0,
    status: "Verified"
  });
  const [error, setError] = useState("");

  useEffect(() => {
    const defaultUniv = universities && universities.length > 0 ? universities[0].name : "University of Mumbai";
    if (initialData) {
      setFormData({ ...initialData });
    } else {
      setFormData({
        name: "",
        university: defaultUniv,
        state: "Maharashtra",
        district: "Pune",
        courses: 20,
        students: 2500,
        graduates: 600,
        placementRate: 85.0,
        internshipRate: 90.0,
        status: "Verified"
      });
    }
  }, [initialData, isOpen, universities]);

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    setError("");

    if (!formData.name || !formData.university) {
      setError("Institution Name and Affiliated University are required.");
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
      <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "600px", background: "#111827", maxHeight: "90vh", overflowY: "auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <GraduationCap size={24} style={{ color: "var(--accent-emerald)" }} />
            <h3 style={{ fontSize: "1.25rem", fontWeight: "700" }}>
              {initialData ? "Edit Institution Record" : "Add New Institution"}
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
            <label>Institution Name *</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Pune Institute of Computer Technology (PICT)"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label>Affiliated University *</label>
            <select
              className="form-select"
              value={formData.university}
              onChange={(e) => setFormData({ ...formData, university: e.target.value })}
            >
              {universities.map(u => (
                <option key={u.id} value={u.name}>{u.name}</option>
              ))}
            </select>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>State *</label>
              <select
                className="form-select"
                value={formData.state}
                onChange={(e) => setFormData({ ...formData, state: e.target.value })}
              >
                {STATES_LIST.filter(s => s !== "All India").map(st => (
                  <option key={st} value={st}>{st}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label>District *</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Pune / Chennai"
                value={formData.district}
                onChange={(e) => setFormData({ ...formData, district: e.target.value })}
                required
              />
            </div>
          </div>

          <div className="grid-3">
            <div className="form-group">
              <label>Courses Offered</label>
              <input
                type="number"
                className="form-control"
                value={formData.courses}
                onChange={(e) => setFormData({ ...formData, courses: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Enrolled Students</label>
              <input
                type="number"
                className="form-control"
                value={formData.students}
                onChange={(e) => setFormData({ ...formData, students: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label>Placement Rate (%)</label>
              <input
                type="number"
                step="0.1"
                className="form-control"
                value={formData.placementRate}
                onChange={(e) => setFormData({ ...formData, placementRate: e.target.value })}
              />
            </div>
          </div>

          <div style={{ marginTop: "24px", display: "flex", justifyContent: "flex-end", gap: "10px" }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              <Save size={16} /> {initialData ? "Save Changes" : "Create Institution"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
