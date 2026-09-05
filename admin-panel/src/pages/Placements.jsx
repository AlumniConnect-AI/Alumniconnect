import { useState, useEffect } from "react";
import { Briefcase, TrendingUp, Award, Users } from "lucide-react";
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid } from "recharts";
import KpiCard from "../components/KpiCard";
import { fetchAdminKpis } from "../services/adminApiService";
import { dataEngine } from "../services/adminDataEngine";
import { useAdminAuth } from "../context/AdminAuthContext";

export default function Placements() {
  const { globalFilters } = useAdminAuth();
  const [kpis, setKpis] = useState(null);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      setLoading(true);
      const res = await fetchAdminKpis(globalFilters);
      setKpis(res);
    } catch (err) {
      console.error("Placements analytics error:", err);
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

  if (loading || !kpis) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--text-muted)" }}>Loading Placement Analytics...</div>;
  }

  const placedStudents = Math.round(kpis.totalGraduates * (kpis.placementRate / 100));

  const trendData = [
    { year: "2022", rate: parseFloat((kpis.placementRate - 7.0).toFixed(1)) },
    { year: "2023", rate: parseFloat((kpis.placementRate - 4.5).toFixed(1)) },
    { year: "2024", rate: parseFloat((kpis.placementRate - 2.0).toFixed(1)) },
    { year: "2025", rate: parseFloat((kpis.placementRate - 0.5).toFixed(1)) },
    { year: "2026", rate: kpis.placementRate }
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      <div>
        <h1 style={{ fontSize: "1.5rem" }}>Placement Analytics & Compensation Intelligence</h1>
        <p style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>
          Employment analytics, campus placement statistics, package distributions, and industry hiring benchmarks in {globalFilters.state}
        </p>
      </div>

      <div className="grid-4">
        <KpiCard title="Total Graduates" value={`${(kpis.totalGraduates / 100000).toFixed(2)} Lakh`} growth={kpis.totalGraduatesGrowth} icon={Users} color="indigo" subtext="Eligible for Placement" />
        <KpiCard title="Students Placed" value={`${(placedStudents / 100000).toFixed(2)} Lakh`} growth="+5.2%" icon={Briefcase} color="emerald" subtext="Verified Corporate Employment" />
        <KpiCard title="National Placement Rate" value={`${kpis.placementRate}%`} growth={kpis.placementRateGrowth} icon={TrendingUp} color="cyan" subtext="Across All Disciplines" />
        <KpiCard title="Internship Transition" value={`${kpis.internshipRate}%`} growth={kpis.internshipRateGrowth} icon={Award} color="amber" subtext="PPO & Apprenticeships" />
      </div>

      <div className="grid-2">
        <KpiCard title="Average Annual Package" value="₹7.8 LPA" growth="+6.1%" icon={TrendingUp} color="emerald" subtext="National Benchmark" />
        <KpiCard title="Highest Package Reported" value="₹54.0 LPA" growth="+12.0%" icon={Award} color="indigo" subtext="Global / Tier-1 Placement" />
      </div>

      {/* Year-wise Placement Trend */}
      <div className="glass-card">
        <h3 style={{ fontSize: "1.1rem", marginBottom: "16px" }}>Dynamic Placement Rate Trend (%) across {globalFilters.state}</h3>
        <div style={{ width: "100%", height: 260 }}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={trendData}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis dataKey="year" tick={{ fill: "#9ca3af", fontSize: 11 }} />
              <YAxis tick={{ fill: "#9ca3af", fontSize: 11 }} domain={[50, 90]} />
              <Tooltip contentStyle={{ background: "#111827", border: "1px solid var(--border-color)", borderRadius: 8 }} />
              <Line type="monotone" dataKey="rate" stroke="#10b981" strokeWidth={3} dot={{ r: 5 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
