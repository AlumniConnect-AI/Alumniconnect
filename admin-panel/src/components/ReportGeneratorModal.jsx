import { useState } from "react";
import { X, FileText, Download } from "lucide-react";
import { STATES_LIST } from "../data/adminMockData";

export default function ReportGeneratorModal({ isOpen, onClose, onSave }) {
  const [formData, setFormData] = useState({
    title: "",
    state: "All India",
    district: "All Districts",
    type: "Annual Performance Summary"
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.title) return;
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
      <div className="glass-card animate-fade-in" style={{ width: "100%", maxWidth: "520px", background: "#111827" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", borderBottom: "1px solid var(--border-color)", paddingBottom: "14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <FileText size={24} style={{ color: "var(--primary)" }} />
            <h3 style={{ fontSize: "1.25rem", fontWeight: "700" }}>Generate Executive Audit Report</h3>
          </div>
          <button className="btn btn-outline btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Report Title *</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Q3 State Educational Outcome & Placement Index"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Report Type</label>
              <select
                className="form-select"
                value={formData.type}
                onChange={(e) => setFormData({ ...formData, type: e.target.value })}
              >
                <option value="Annual Performance">Annual Performance Summary</option>
                <option value="State Analytics">State Higher Ed Analytics</option>
                <option value="Placement Index">Placement & Package Index</option>
                <option value="Diagnostic Audit">Diagnostic Intervention Audit</option>
              </select>
            </div>

            <div className="form-group">
              <label>Target Scope / State</label>
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
              <Download size={16} /> Generate & Compile Report
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
