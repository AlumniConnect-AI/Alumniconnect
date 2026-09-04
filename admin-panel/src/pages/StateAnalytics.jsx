import { useState, useEffect } from "react";
import { MapPin, Building2, School, Users, Award, BookOpen } from "lucide-react";
import KpiCard from "../components/KpiCard";
import DataTable from "../components/DataTable";
import StatusBadge from "../components/StatusBadge";
import { fetchAdminKpis, fetchStateOverview } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";
import { useAdminAuth } from "../context/AdminAuthContext";

export default function StateAnalytics() {
  const { globalFilters } = useAdminAuth();
  const [kpis, setKpis] = useState(null);
  const [stateOverview, setStateOverview] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      setLoading(true);
      const [kpiRes, overviewRes] = await Promise.all([
        fetchAdminKpis(globalFilters),
        fetchStateOverview(globalFilters)
      ]);
      setKpis(kpiRes);
      setStateOverview(overviewRes);
    } catch (err) {
      console.error("State analytics load error:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    const unsubscribe = dataEngine.subscribe(() => {
      loadData();
    });
    return () => unsubscribe();
  }, [globalFilters]);

  const tableColumns = [
    {
      header: "State / Jurisdiction",
      accessorKey: "state",
      cell: (r) => <strong>{r.state}</strong>
    },
    { header: "Universities", accessorKey: "universities" },
    { header: "Affiliated Colleges", accessorKey: "institutions", cell: (r) => (r.institutions || 0).toLocaleString() },
    { header: "Total Students", accessorKey: "students", cell: (r) => (r.students || 0).toLocaleString() },
    { header: "Graduates", accessorKey: "graduates", cell: (r) => (r.graduates || 0).toLocaleString() },
    { header: "Placement Rate", accessorKey: "placementRate", cell: (r) => <span style={{ color: "#34d399", fontWeight: "700" }}>{r.placementRate}%</span> },
    { header: "Graduation Rate", accessorKey: "graduationRate", cell: (r) => <span style={{ color: "#38bdf8", fontWeight: "700" }}>{r.graduationRate}%</span> },
    { header: "Career Outcome Index", accessorKey: "careerOutcome", cell: (r) => `${r.careerOutcome}%` }
  ];

  if (loading || !kpis) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>Loading State Analytics...</div>;
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <div>
        <h1 style={{ fontSize: "1.5rem" }}>State & District Level Analytics Portal</h1>
        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
          Hierarchical drill-down analytics: India → State ({globalFilters.state}) → District ({globalFilters.district}) → University → College → Course
        </p>
      </div>

      {/* Selected Scope Banner */}
      <div className="glass-card" style={{ borderColor: "rgba(6, 182, 212, 0.3)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px", flexWrap: "wrap" }}>
          <MapPin size={22} style={{ color: "var(--accent-cyan)" }} />
          <div>
            <div style={{ fontSize: "0.8rem", color: "var(--text-muted)" }}>Active Filter Selection Scope</div>
            <div style={{ fontSize: "1.1rem", fontWeight: "700", color: "#f9fafb" }}>
              {globalFilters.country} / {globalFilters.state} / {globalFilters.district} / {globalFilters.university} / {globalFilters.academicYear}
            </div>
          </div>
        </div>
      </div>

      <div className="grid-4">
        <KpiCard title="Universities in Scope" value={kpis.totalUniversities.toLocaleString()} icon={Building2} color="indigo" subtext="Registered Bodies" />
        <KpiCard title="Institutions in Scope" value={kpis.totalInstitutions.toLocaleString()} icon={School} color="cyan" subtext="Affiliated & Autonomous" />
        <KpiCard title="Students in Scope" value={`${(kpis.totalStudents / 10000000).toFixed(2)} Cr`} icon={Users} color="emerald" subtext="Active Enrollments" />
        <KpiCard title="Placement Rate" value={`${kpis.placementRate}%`} icon={Award} color="amber" subtext="State Benchmark" />
      </div>

      <div className="grid-4">
        <KpiCard title="Graduation Rate" value={`${kpis.graduationRate}%`} icon={Award} color="cyan" subtext="Degree Awarded" />
        <KpiCard title="Internship Participation" value={`${kpis.internshipRate}%`} icon={Award} color="emerald" subtext="Verified PPO/Apprenticeship" />
        <KpiCard title="Higher Studies Rate" value={`${kpis.higherStudiesRate}%`} icon={BookOpen} color="indigo" subtext="Post-Graduate Enrolled" />
        <KpiCard title="Career Outcome Index" value={`${kpis.careerOutcomeRate}%`} icon={Award} color="amber" subtext="Total Employed & Pursuing" />
      </div>

      <div className="glass-card">
        <h3 style={{ fontSize: "1.1rem", marginBottom: "16px" }}>State Jurisdictional Performance Directory</h3>
        <DataTable columns={tableColumns} data={stateOverview} searchPlaceholder="Search state or region..." />
      </div>
    </div>
  );
}
