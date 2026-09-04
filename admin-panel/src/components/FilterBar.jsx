import { Filter, RotateCcw, Globe, MapPin, Building2, BookOpen, Calendar } from "lucide-react";
import { useAdminAuth } from "../context/AdminAuthContext";
import { STATES_LIST } from "../data/adminMockData";

export default function FilterBar() {
  const { globalFilters, updateFilters } = useAdminAuth();

  const handleStateChange = (e) => {
    updateFilters({ state: e.target.value, district: "All Districts" });
  };

  const handleReset = () => {
    updateFilters({
      country: "India",
      state: "All India",
      district: "All Districts",
      university: "All Universities",
      institution: "All Institutions",
      course: "All Courses",
      academicYear: "2025-2026"
    });
  };

  return (
    <div
      style={{
        background: "rgba(17, 24, 39, 0.9)",
        border: "1px solid var(--border-color)",
        borderRadius: "var(--radius-lg)",
        padding: "16px 20px",
        marginBottom: "24px",
        display: "flex",
        flexDirection: "column",
        gap: "14px"
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", fontWeight: "600", fontSize: "0.9rem", color: "var(--primary)" }}>
          <Filter size={18} />
          <span>Global Administration Filter System</span>
          <span className="badge badge-indigo" style={{ marginLeft: "8px" }}>Scope: {globalFilters.state}</span>
        </div>
        <button
          onClick={handleReset}
          className="btn btn-outline btn-sm"
          style={{ gap: "6px" }}
          title="Reset filters to default"
        >
          <RotateCcw size={14} />
          <span>Reset Filters</span>
        </button>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))",
          gap: "12px"
        }}
      >
        {/* Country */}
        <div>
          <label style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px", marginBottom: "4px" }}>
            <Globe size={12} /> Country
          </label>
          <select
            className="form-select"
            value={globalFilters.country}
            onChange={(e) => updateFilters({ country: e.target.value })}
            style={{ padding: "8px 12px", fontSize: "0.85rem" }}
          >
            <option value="India">India (National)</option>
          </select>
        </div>

        {/* State */}
        <div>
          <label style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px", marginBottom: "4px" }}>
            <MapPin size={12} /> State
          </label>
          <select
            className="form-select"
            value={globalFilters.state}
            onChange={handleStateChange}
            style={{ padding: "8px 12px", fontSize: "0.85rem" }}
          >
            {STATES_LIST.map((st) => (
              <option key={st} value={st}>{st}</option>
            ))}
          </select>
        </div>

        {/* District */}
        <div>
          <label style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px", marginBottom: "4px" }}>
            <MapPin size={12} /> District
          </label>
          <select
            className="form-select"
            value={globalFilters.district}
            onChange={(e) => updateFilters({ district: e.target.value })}
            style={{ padding: "8px 12px", fontSize: "0.85rem" }}
          >
            <option value="All Districts">All Districts</option>
            <option value="Mumbai City">Mumbai City</option>
            <option value="Pune">Pune</option>
            <option value="Nagpur">Nagpur</option>
            <option value="Chennai">Chennai</option>
            <option value="Bengaluru">Bengaluru</option>
            <option value="Hyderabad">Hyderabad</option>
            <option value="Ahmedabad">Ahmedabad</option>
          </select>
        </div>

        {/* University */}
        <div>
          <label style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px", marginBottom: "4px" }}>
            <Building2 size={12} /> University
          </label>
          <select
            className="form-select"
            value={globalFilters.university}
            onChange={(e) => updateFilters({ university: e.target.value })}
            style={{ padding: "8px 12px", fontSize: "0.85rem" }}
          >
            <option value="All Universities">All Universities</option>
            <option value="University of Mumbai">University of Mumbai</option>
            <option value="Savitribai Phule Pune University">SPPU Pune</option>
            <option value="Anna University">Anna University</option>
            <option value="VTU Karnataka">VTU Karnataka</option>
            <option value="JNTU Hyderabad">JNTU Hyderabad</option>
          </select>
        </div>

        {/* Institution */}
        <div>
          <label style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px", marginBottom: "4px" }}>
            <Building2 size={12} /> Institution
          </label>
          <select
            className="form-select"
            value={globalFilters.institution}
            onChange={(e) => updateFilters({ institution: e.target.value })}
            style={{ padding: "8px 12px", fontSize: "0.85rem" }}
          >
            <option value="All Institutions">All Institutions</option>
            <option value="VJTI Mumbai">VJTI Mumbai</option>
            <option value="COEP Pune">COEP Pune</option>
            <option value="CEG Chennai">CEG Chennai</option>
            <option value="BMSCE Bengaluru">BMSCE Bengaluru</option>
          </select>
        </div>

        {/* Course */}
        <div>
          <label style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px", marginBottom: "4px" }}>
            <BookOpen size={12} /> Course
          </label>
          <select
            className="form-select"
            value={globalFilters.course}
            onChange={(e) => updateFilters({ course: e.target.value })}
            style={{ padding: "8px 12px", fontSize: "0.85rem" }}
          >
            <option value="All Courses">All Courses</option>
            <option value="B.Tech Computer Science">B.Tech Computer Science</option>
            <option value="B.Tech Information Tech">B.Tech Information Tech</option>
            <option value="B.Tech AI & Data Science">B.Tech AI & Data Science</option>
            <option value="MBA Management">MBA Management</option>
          </select>
        </div>

        {/* Year */}
        <div>
          <label style={{ fontSize: "0.75rem", color: "var(--text-muted)", display: "flex", alignItems: "center", gap: "4px", marginBottom: "4px" }}>
            <Calendar size={12} /> Academic Year
          </label>
          <select
            className="form-select"
            value={globalFilters.academicYear}
            onChange={(e) => updateFilters({ academicYear: e.target.value })}
            style={{ padding: "8px 12px", fontSize: "0.85rem" }}
          >
            <option value="2025-2026">2025 - 2026</option>
            <option value="2024-2025">2024 - 2025</option>
            <option value="2023-2024">2023 - 2024</option>
          </select>
        </div>
      </div>
    </div>
  );
}
