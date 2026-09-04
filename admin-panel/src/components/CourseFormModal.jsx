import { useState, useEffect } from "react";
import { X, BookOpen, Save } from "lucide-react";

export default function CourseFormModal({ isOpen, onClose, onSave, initialData }) {
  const [formData, setFormData] = useState({
    name: "",
    stream: "Engineering",
    students: 50000,
    graduates: 12000,
    placementRate: 75.0,
    higherStudiesRate: 12.0,
    demandLevel: "High",
    topSkills: "Python, Problem Solving",
    accountabilityStatus: "Good"
  });

  useEffect(() => {
    if (initialData) {
      setFormData({ ...initialData });
    } else {
      setFormData({
        name: "",
        stream: "Engineering",
        students: 50000,
        graduates: 12000,
        placementRate: 75.0,
        higherStudiesRate: 12.0,
        demandLevel: "High",
        topSkills: "Python, Problem Solving",
        accountabilityStatus: "Good"
      });
    }
  }, [initialData, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name) return;
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
      <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "560px", background: "#111827", maxHeight: "90vh", overflowY: "auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <BookOpen size={24} style={{ color: "var(--accent-cyan)" }} />
            <h3 style={{ fontSize: "1.25rem", fontWeight: "700" }}>
              {initialData ? "Edit Academic Course" : "Add New Academic Course"}
            </h3>
          </div>
          <button className="btn btn-outline btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Course Title *</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. B.Tech Artificial Intelligence & Robotics"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Academic Stream</label>
              <select
                className="form-select"
                value={formData.stream}
                onChange={(e) => setFormData({ ...formData, stream: e.target.value })}
              >
                <option value="Engineering">Engineering</option>
                <option value="Management">Management</option>
                <option value="Science">Science</option>
                <option value="Arts & Humanities">Arts & Humanities</option>
                <option value="Medical & Health">Medical & Health</option>
              </select>
            </div>

            <div className="form-group">
              <label>Demand Level</label>
              <select
                className="form-select"
                value={formData.demandLevel}
                onChange={(e) => setFormData({ ...formData, demandLevel: e.target.value })}
              >
                <option value="Very High">Very High</option>
                <option value="High">High</option>
                <option value="Medium">Medium</option>
                <option value="Low">Low</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label>Top Industry Skills (Comma separated)</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Python, TensorFlow, PyTorch, Data Structures"
              value={formData.topSkills}
              onChange={(e) => setFormData({ ...formData, topSkills: e.target.value })}
            />
          </div>

          <div className="grid-2">
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

            <div className="form-group">
              <label>Accountability Rating</label>
              <select
                className="form-select"
                value={formData.accountabilityStatus}
                onChange={(e) => setFormData({ ...formData, accountabilityStatus: e.target.value })}
              >
                <option value="Excellent">Excellent</option>
                <option value="Good">Good</option>
                <option value="Average">Average</option>
                <option value="Needs Improvement">Needs Improvement</option>
              </select>
            </div>
          </div>

          <div style={{ marginTop: "24px", display: "flex", justifyContent: "flex-end", gap: "10px" }}>
            <button type="button" className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary">
              <Save size={16} /> {initialData ? "Save Changes" : "Create Course"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
