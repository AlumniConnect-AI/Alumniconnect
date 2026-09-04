import { useState, useEffect } from "react";
import { Settings as SettingsIcon, ShieldCheck, CheckCircle2, AlertCircle, FileCheck, Save } from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import { fetchConsentCompliance } from "../services/adminApiService";
import { useAdminAuth } from "../context/AdminAuthContext";

export default function Settings() {
  const { adminUser } = useAdminAuth();
  const [consentData, setConsentData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        setLoading(true);
        const res = await fetchConsentCompliance();
        setConsentData(res);
      } catch (err) {
        console.error("Failed to fetch consent compliance:", err);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <div>
        <h1 style={{ fontSize: "1.5rem" }}>Admin Portal Settings & Compliance Governance</h1>
        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
          Council administration profiles, student data consent compliance, and follow-up response tracking
        </p>
      </div>

      {/* Section 20 - Data Consent & Compliance */}
      <div className="glass-card">
        <div style={{ marginBottom: "16px" }}>
          <h3 style={{ fontSize: "1.1rem", display: "flex", alignItems: "center", gap: "8px" }}>
            <FileCheck size={20} style={{ color: "var(--accent-emerald)" }} />
            Student Data Consent & Privacy Compliance Overview
          </h3>
          <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
            Aggregated compliance metrics under Data Protection & Privacy Guidelines (No PII exposed)
          </p>
        </div>

        {loading || !consentData ? (
          <div style={{ color: "var(--text-muted)" }}>Loading consent metrics...</div>
        ) : (
          <div className="grid-5">
            <div style={{ background: "rgba(255,255,255,0.03)", padding: "16px", borderRadius: "var(--radius-md)" }}>
              <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Total Student Records</div>
              <div style={{ fontSize: "1.3rem", fontWeight: "700", marginTop: "4px" }}>{consentData.totalRecords.toLocaleString()}</div>
            </div>
            <div style={{ background: "rgba(16, 185, 129, 0.08)", border: "1px solid rgba(16, 185, 129, 0.2)", padding: "16px", borderRadius: "var(--radius-md)" }}>
              <div style={{ fontSize: "0.75rem", color: "#34d399" }}>Consent Given</div>
              <div style={{ fontSize: "1.3rem", fontWeight: "700", marginTop: "4px", color: "#34d399" }}>{consentData.consentGiven.toLocaleString()}</div>
            </div>
            <div style={{ background: "rgba(245, 158, 11, 0.08)", border: "1px solid rgba(245, 158, 11, 0.2)", padding: "16px", borderRadius: "var(--radius-md)" }}>
              <div style={{ fontSize: "0.75rem", color: "#fbbf24" }}>Consent Pending</div>
              <div style={{ fontSize: "1.3rem", fontWeight: "700", marginTop: "4px", color: "#fbbf24" }}>{consentData.consentPending.toLocaleString()}</div>
            </div>
            <div style={{ background: "rgba(244, 63, 94, 0.08)", border: "1px solid rgba(244, 63, 94, 0.2)", padding: "16px", borderRadius: "var(--radius-md)" }}>
              <div style={{ fontSize: "0.75rem", color: "#f87171" }}>Consent Revoked</div>
              <div style={{ fontSize: "1.3rem", fontWeight: "700", marginTop: "4px", color: "#f87171" }}>{consentData.consentRevoked.toLocaleString()}</div>
            </div>
            <div style={{ background: "rgba(6, 182, 212, 0.08)", border: "1px solid rgba(6, 182, 212, 0.2)", padding: "16px", borderRadius: "var(--radius-md)" }}>
              <div style={{ fontSize: "0.75rem", color: "#38bdf8" }}>Compliance Rate</div>
              <div style={{ fontSize: "1.3rem", fontWeight: "700", marginTop: "4px", color: "#38bdf8" }}>{consentData.consentRate}%</div>
            </div>
          </div>
        )}
      </div>

      {/* Section 19 - Follow-up / Outcome Compliance */}
      <div className="glass-card">
        <div style={{ marginBottom: "16px" }}>
          <h3 style={{ fontSize: "1.1rem" }}>Follow-up & Outcome Data Completion Compliance</h3>
          <p style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>
            Tracking data completion targets for institution-level career outcome tracking
          </p>
        </div>

        <div className="grid-4">
          <div style={{ background: "rgba(255,255,255,0.03)", padding: "16px", borderRadius: "var(--radius-md)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Target Students</div>
            <div style={{ fontSize: "1.2rem", fontWeight: "700", marginTop: "4px" }}>62.1 Lakh</div>
          </div>
          <div style={{ background: "rgba(255,255,255,0.03)", padding: "16px", borderRadius: "var(--radius-md)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Students Followed Up</div>
            <div style={{ fontSize: "1.2rem", fontWeight: "700", marginTop: "4px", color: "#38bdf8" }}>54.8 Lakh</div>
          </div>
          <div style={{ background: "rgba(255,255,255,0.03)", padding: "16px", borderRadius: "var(--radius-md)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Recorded Outcomes</div>
            <div style={{ fontSize: "1.2rem", fontWeight: "700", marginTop: "4px", color: "#34d399" }}>52.5 Lakh</div>
          </div>
          <div style={{ background: "rgba(255,255,255,0.03)", padding: "16px", borderRadius: "var(--radius-md)" }}>
            <div style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Response Rate</div>
            <div style={{ fontSize: "1.2rem", fontWeight: "700", marginTop: "4px", color: "#fbbf24" }}>88.2% (Target: 90%)</div>
          </div>
        </div>
      </div>

      {/* Admin Profile & Council Setup Form */}
      <div className="glass-card">
        <h3 style={{ fontSize: "1.1rem", marginBottom: "16px" }}>Admin Account & Council Configuration</h3>
        <form onSubmit={(e) => { e.preventDefault(); alert("Admin settings saved successfully."); }}>
          <div className="grid-2">
            <div className="form-group">
              <label>Full Name</label>
              <input type="text" className="form-control" defaultValue={adminUser?.name || "Dr. Rajesh V. Sharma"} />
            </div>
            <div className="form-group">
              <label>Official Email</label>
              <input type="email" className="form-control" defaultValue={adminUser?.email || "admin@maharashtra.edu.gov.in"} disabled />
            </div>
          </div>

          <div className="grid-2">
            <div className="form-group">
              <label>Organization / Council</label>
              <input type="text" className="form-control" defaultValue={adminUser?.organization || "Maharashtra State Council"} />
            </div>
            <div className="form-group">
              <label>Designation</label>
              <input type="text" className="form-control" defaultValue={adminUser?.designation || "Senior Analytics Director"} />
            </div>
          </div>

          <button type="submit" className="btn btn-primary" style={{ marginTop: "12px" }}>
            <Save size={16} /> Save Admin Settings
          </button>
        </form>
      </div>
    </div>
  );
}
