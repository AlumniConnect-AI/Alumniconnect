import { useState, useEffect } from "react";
import { TrendingUp, HelpCircle, Clock } from "lucide-react";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import { fetchCareerOutcomes } from "../services/adminApiService";

export default function CareerOutcomes() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        setLoading(true);
        const res = await fetchCareerOutcomes();
        setData(res);
      } catch (err) {
        console.error("Failed to fetch career outcomes:", err);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading || !data) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>Loading Career Outcomes...</div>;
  }

  const outcomeColumns = [
    { header: "Career Path Category", accessorKey: "category", cell: (r) => <strong>{r.category}</strong> },
    { header: "Student Count", accessorKey: "count", cell: (r) => r.count.toLocaleString() },
    { header: "Percentage", accessorKey: "percentage", cell: (r) => <span style={{ fontWeight: "700", color: "#38bdf8" }}>{r.percentage}%</span> },
    { header: "Yearly Growth", accessorKey: "trend", cell: (r) => <StatusBadge status={r.trend} /> }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <div>
        <h1 style={{ fontSize: "1.5rem" }}>Career Outcome & Longitudinal Progression</h1>
        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
          Tracking graduate outcomes beyond initial placements: higher studies, entrepreneurship, government service, and non-placement diagnostics
        </p>
      </div>

      {/* Main Career Outcomes Table - Section 16 */}
      <div className="glass-card">
        <h3 style={{ fontSize: "1.1rem", marginBottom: "16px" }}>Graduate Career Outcome Categories</h3>
        <DataTable columns={outcomeColumns} data={data.outcomes} searchPlaceholder="Search career category..." />
      </div>

      {/* Section 17 - Non-Placement / Outcome Reasons */}
      <div className="glass-card">
        <div style={{ marginBottom: "16px" }}>
          <h3 style={{ fontSize: "1.1rem", display: "flex", alignItems: "center", gap: "8px" }}>
            <HelpCircle size={20} style={{ color: "var(--accent-amber)" }} />
            Non-Placement & Alternative Path Diagnostic Analysis
          </h3>
          <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
            Understanding why non-placed students did not enter immediate corporate employment
          </p>
        </div>
        <div className="table-responsive" style={{ border: "1px solid var(--border-color)", borderRadius: "var(--radius-md)" }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Reason / Path Description</th>
                <th>Student Count</th>
                <th>Percentage of Non-Placed</th>
              </tr>
            </thead>
            <tbody>
              {data.nonPlacementReasons.map((item, idx) => (
                <tr key={idx}>
                  <td><strong>{item.reason}</strong></td>
                  <td>{item.count.toLocaleString()}</td>
                  <td><span className="badge badge-amber">{item.percentage}%</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Section 21 - Retention / Long-Term Outcome */}
      <div className="glass-card">
        <div style={{ marginBottom: "16px" }}>
          <h3 style={{ fontSize: "1.1rem", display: "flex", alignItems: "center", gap: "8px" }}>
            <Clock size={20} style={{ color: "var(--primary)" }} />
            Longitudinal Career Retention & Progression (6M, 12M, 24M)
          </h3>
          <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
            Tracking long-term employment stability and higher education retention over time
          </p>
        </div>
        <div className="grid-3">
          {data.longTermRetention.map((ret, idx) => (
            <div key={idx} style={{ background: "rgba(255,255,255,0.03)", border: "1px solid var(--border-color)", padding: "20px", borderRadius: "var(--radius-md)" }}>
              <div style={{ fontSize: "0.85rem", color: "var(--primary)", fontWeight: "700" }}>{ret.period}</div>
              <div style={{ marginTop: "12px", display: "flex", flexDirection: "column", gap: "6px", fontSize: "0.85rem" }}>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: "var(--text-muted)" }}>Employment Retention:</span>
                  <strong style={{ color: "#34d399" }}>{ret.employmentRetention}%</strong>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: "var(--text-muted)" }}>Higher Education Retention:</span>
                  <strong style={{ color: "#38bdf8" }}>{ret.higherStudiesRetention}%</strong>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ color: "var(--text-muted)" }}>Career Progression Index:</span>
                  <strong style={{ color: "#818cf8" }}>{ret.progressionIndex}%</strong>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
